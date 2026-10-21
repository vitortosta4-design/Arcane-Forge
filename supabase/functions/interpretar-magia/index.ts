// O "porteiro" da ADR-003: guarda a chave da IA, limita o uso e chama a
// Groq. Nunca decide se a magia vale ou quanto custa (isso é o Validador,
// dentro do jogo) — só traduz a frase para uma ficha (proposta técnica,
// seção 4).
//
// Este arquivo é a fonte de verdade versionada no git. O deploy de verdade
// acontece via MCP do Supabase (mcp__claude_ai_Supabase__deploy_edge_function);
// depois de editar aqui, lembrar de reimplantar.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const MATERIAIS_VALIDOS = ["pedra", "agua", "fogo", "metal", "madeira"];
const FORMAS_VALIDAS = ["esfera", "ovo", "cubo"];
const LIMITE_FRASE = 200; // proposta técnica, seção 5
const LIMITE_POR_MINUTO = 20; // proposta técnica, seção 5
const VERSAO_SISTEMA = 1;

// Escolha provisória da Fase 2 (ver docs/decisoes.md). Pode trocar sem
// mexer em mais nada além desta constante. Conferido em 20/10/2026 contra
// GET https://api.groq.com/openai/v1/models (a lista de modelos da Groq
// muda; não supor que um nome continua existindo sem checar).
const MODELO_GROQ = "openai/gpt-oss-120b";

const SYSTEM_PROMPT = `
Você é o garçom de um jogo de magia (Arcane Forge). Sua única tarefa é
traduzir uma frase em português, descrevendo uma magia, para uma ficha
estruturada em JSON. Você NUNCA decide se a magia é permitida, nem calcula
dano, custo ou limites: isso é feito por outro sistema depois de você. Você
só traduz a ideia.

Hoje o jogo sabe montar magias com estes componentes (cada ficha pode ter um
ou mais, numa lista):

- "projetil": voa até o alvo e pode causar efeitos ao impactar (campo
  "ao_impactar", uma lista):
  - "explosao": dano numa área. O "empurrao" aceita número negativo para
    PUXAR para o centro em vez de afastar (ex.: "um buraco negro que
    atrai os inimigos" vira um projétil com "empurrao": -5 e "dano": 0).
  - "estado": aplica um efeito só em quem o projétil atingiu (não numa
    área). Hoje só existem dois: "queimando" (dano aos poucos, por
    "duracao_s") e "lento" (deixa quem foi atingido mais devagar, por
    "duracao_s"). NÃO use nenhum outro nome de estado (ex.: molhado,
    eletrizado, cego) — ainda não existem no jogo.
  Aproxime qualquer ideia de ataque para esse formato (por exemplo, "um
  raio congelante" pode virar um projétil de gelo com "estado": "lento").
- "cura": recupera vida de quem conjurou, na hora, sem precisar de alvo.
  Use para qualquer ideia de curar, recuperar ou restaurar.
- "escudo": reduz o dano que quem conjurou recebe, por um tempo. Use para
  qualquer ideia de proteção, armadura ou barreira.
- "invocacao": cria uma criatura que persegue e ataca o inimigo mais
  próximo sozinha. Campos: "corpo" ("ave" | "quadrupede" | "verme" |
  "bolha"), "material" (mesma lista do projétil), "escala" (ex.: 0.7 para
  menor que o normal, 1.5 para maior), "vida", "duracao_s" e
  "dano_contato" (dano que ela causa a cada ataque). "comportamento" tem
  que ser sempre "perseguir_inimigo_proximo" — é o único que existe. Use
  para qualquer ideia de invocar, trazer ou criar uma criatura para
  ajudar.

Uma magia pode combinar mais de um componente na mesma lista (ex.: um
projétil E um escudo ao mesmo tempo), mas só se a frase descrever as duas
coisas. Use a "legenda" para comunicar a ideia original ao jogador.

Se a frase NÃO parecer descrever uma magia de verdade (letras aleatórias,
frase sem sentido, pedido vazio, ou qualquer coisa que não dê para
transformar em nenhum desses componentes), responda com "componentes"
como uma lista VAZIA ([]) e explique isso na "legenda". Nunca invente uma
magia com dano, raio, velocidade, cura ou redução zerados só para
preencher o formato: nesse caso o certo é devolver a lista de componentes
vazia mesmo.

Responda SOMENTE com um JSON válido, sem markdown, sem texto antes ou
depois, exatamente neste formato (omita os componentes e os efeitos de
"ao_impactar" que não se aplicarem à magia pedida — o exemplo abaixo mostra
"explosao" e "estado" juntos só para ilustrar o formato de cada um, a
maioria das magias usa só um dos dois):

{
  "nome": "string curta e criativa",
  "natureza": "boa" | "neutra" | "ma",
  "ingredientes": ["palavras-chave livres que resumem a magia, ex: fogo, voo"],
  "componentes": [
    {
      "tipo": "projetil",
      "forma": "${FORMAS_VALIDAS.join('" | "')}",
      "material": "${MATERIAIS_VALIDOS.join('" | "')}",
      "velocidade": 10,
      "ao_impactar": [
        {
          "tipo": "explosao",
          "raio_m": 2,
          "dano": 10,
          "empurrao": 2,
          "etiquetas": ["fogo"]
        },
        {
          "tipo": "estado",
          "nome_estado": "queimando",
          "duracao_s": 3
        }
      ]
    },
    {
      "tipo": "cura",
      "quantidade": 15
    },
    {
      "tipo": "escudo",
      "reducao": 0.4,
      "duracao_s": 4
    },
    {
      "tipo": "invocacao",
      "corpo": "ave",
      "material": "pedra",
      "escala": 0.7,
      "comportamento": "perseguir_inimigo_proximo",
      "vida": 20,
      "duracao_s": 6,
      "dano_contato": 5
    }
  ],
  "legenda": "frase curta em português descrevendo o que foi entendido"
}
`.trim();

function jsonResponse(corpo: unknown, status = 200): Response {
	return new Response(JSON.stringify(corpo), {
		status,
		headers: { "Content-Type": "application/json" },
	});
}

async function conferirLimite(
	supabase: ReturnType<typeof createClient>,
	salaId: string,
): Promise<boolean> {
	const umMinutoAtras = new Date(Date.now() - 60_000).toISOString();
	const { count } = await supabase
		.from("limite_conjuracao")
		.select("id", { count: "exact", head: true })
		.eq("sala_id", salaId)
		.gte("criado_em", umMinutoAtras);

	if ((count ?? 0) >= LIMITE_POR_MINUTO) {
		return false;
	}
	await supabase.from("limite_conjuracao").insert({ sala_id: salaId });
	return true;
}

async function registrarFalha(
	supabase: ReturnType<typeof createClient>,
	frase: string,
	respostaBruta: string,
	motivo: string,
) {
	await supabase.from("fichas_falhas").insert({
		frase,
		resposta_bruta: respostaBruta?.slice(0, 4000) ?? null,
		motivo,
		versao_sistema: VERSAO_SISTEMA,
	});
}

Deno.serve(async (req: Request) => {
	if (req.method !== "POST") {
		return jsonResponse({ erro: "método não suportado" }, 405);
	}

	let corpo: { frase?: string; sala_id?: string };
	try {
		corpo = await req.json();
	} catch {
		return jsonResponse({ erro: "corpo inválido" }, 400);
	}

	const frase = (corpo.frase ?? "").toString().trim();
	const salaId = (corpo.sala_id ?? "desconhecida").toString().slice(0, 100);

	if (frase.length === 0) {
		return jsonResponse({ erro: "frase vazia" }, 400);
	}
	if (frase.length > LIMITE_FRASE) {
		return jsonResponse({ erro: `frase maior que ${LIMITE_FRASE} caracteres` }, 400);
	}

	const supabase = createClient(
		Deno.env.get("SUPABASE_URL")!,
		Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
	);

	const dentroDoLimite = await conferirLimite(supabase, salaId);
	if (!dentroDoLimite) {
		return jsonResponse(
			{ erro: "limite de conjurações por minuto atingido, espere um pouco" },
			429,
		);
	}

	const groqKey = Deno.env.get("GROQ_API_KEY");
	if (!groqKey) {
		return jsonResponse({ erro: "interpretador fora do ar (sem chave configurada)" }, 503);
	}

	let respostaBruta = "";
	try {
		const respostaGroq = await fetch("https://api.groq.com/openai/v1/chat/completions", {
			method: "POST",
			headers: {
				"Authorization": `Bearer ${groqKey}`,
				"Content-Type": "application/json",
			},
			body: JSON.stringify({
				model: MODELO_GROQ,
				messages: [
					{ role: "system", content: SYSTEM_PROMPT },
					{ role: "user", content: frase },
				],
				response_format: { type: "json_object" },
				temperature: 0.7,
			}),
		});

		if (!respostaGroq.ok) {
			const texto = await respostaGroq.text();
			await registrarFalha(supabase, frase, texto, "groq_erro_http_" + respostaGroq.status);
			return jsonResponse({ erro: "interpretador instável agora" }, 502);
		}

		const dadosGroq = await respostaGroq.json();
		respostaBruta = dadosGroq.choices?.[0]?.message?.content ?? "";
	} catch (erro) {
		await registrarFalha(supabase, frase, String(erro), "groq_erro_rede");
		return jsonResponse({ erro: "interpretador instável agora" }, 502);
	}

	let ficha: Record<string, unknown>;
	try {
		ficha = JSON.parse(respostaBruta);
	} catch {
		await registrarFalha(supabase, frase, respostaBruta, "json_invalido");
		return jsonResponse({ erro: "não consegui entender essa magia" }, 422);
	}

	ficha["versao_sistema"] = VERSAO_SISTEMA;
	ficha["frase_original"] = frase;

	return jsonResponse({ ficha });
});
