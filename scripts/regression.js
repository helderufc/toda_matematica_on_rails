/**
 * k6 Regression + Load Test — Toda Matemática API
 *
 * Perfil de carga:
 *   1 min  → sobe p/ 300 VUs (aquecimento)
 *   3 min  → sustenta 300 VUs (estado estável)
 *   2 min  → sobe p/ 2700 VUs (pico)
 *   2 min  → sustenta 2700 VUs
 *   2 min  → volta p/ 300 VUs (recuperação)
 *   1 min  → vai p/ 0 (desaquecimento)
 *
 * Divisão por iteração:
 *   75 % → leituras  (todos os GETs)
 *   20 % → escrita   (fluxo CRUD completo)
 *    5 % → IA        (gerar → pendente → confirmar)
 *
 * Variáveis de ambiente:
 *   BASE_URL   (default: http://localhost:3000)
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

const JSON_HDR = { 'Content-Type': 'application/json', Accept: 'application/json' };
const GET_HDR  = { Accept: 'application/json' };

// ─── Perfil de carga ──────────────────────────────────────────────────────────

export const options = {
  stages: [
    { duration: '1m',  target: 300  },  // aquecimento
    { duration: '3m',  target: 300  },  // estado estável
    { duration: '2m',  target: 2700 },  // subida ao pico
    { duration: '2m',  target: 2700 },  // sustentação do pico
    { duration: '2m',  target: 300  },  // recuperação
    { duration: '1m',  target: 0    },  // desaquecimento
  ],
  thresholds: {
    http_req_failed:                       ['rate<0.01'],        // < 1 % de erros
    http_req_duration:                     ['p(95)<500', 'p(99)<1500'],
    'http_req_duration{group:::reads}':    ['p(95)<300'],
    'http_req_duration{group:::writes}':   ['p(95)<800'],
    'http_req_duration{group:::ia}':       ['p(95)<1200'],
  },
};

// ─── Setup: cria dados base usados pelas leituras ─────────────────────────────

export function setup() {
  const ts = Date.now();

  // Course
  const cRes = http.post(
    `${BASE_URL}/courses`,
    JSON.stringify({ course: { title: `k6 Base ${ts}`, category: 'Load', description: 'Setup k6.' } }),
    { headers: JSON_HDR },
  );
  if (cRes.status !== 201) throw new Error(`setup POST /courses falhou ${cRes.status}: ${cRes.body}`);
  const courseId = cRes.json('id');

  // Module
  const mRes = http.post(
    `${BASE_URL}/courses/${courseId}/modules`,
    JSON.stringify({ modulo: { name: `Módulo Setup ${ts}` } }),
    { headers: JSON_HDR },
  );
  if (mRes.status !== 201) throw new Error(`setup POST /courses/${courseId}/modules falhou`);
  const moduleId = mRes.json('id');

  // Lesson
  const lRes = http.post(
    `${BASE_URL}/modules/${moduleId}/lessons`,
    JSON.stringify({ lesson: { name: `Aula Setup ${ts}`, content_editor: 'Conteúdo de setup k6.' } }),
    { headers: JSON_HDR },
  );
  if (lRes.status !== 201) throw new Error(`setup POST /modules/${moduleId}/lessons falhou`);
  const lessonId = lRes.json('id');

  // Quiz com duas questões
  const quizRes = http.post(
    `${BASE_URL}/modules/${moduleId}/quiz`,
    JSON.stringify({
      quiz: {
        show_correct_answers: true,
        show_points: true,
        show_wrong_answers: false,
        questions_attributes: [
          {
            statement: 'Qual é a identidade aditiva?',
            points: 1,
            alternatives_attributes: [
              { text: '0',  correct: true  },
              { text: '1',  correct: false },
              { text: '-1', correct: false },
            ],
          },
          {
            statement: 'Quanto é 2²?',
            points: 2,
            alternatives_attributes: [
              { text: '4', correct: true  },
              { text: '2', correct: false },
            ],
          },
        ],
      },
    }),
    { headers: JSON_HDR },
  );
  if (quizRes.status !== 201) throw new Error(`setup POST /modules/${moduleId}/quiz falhou`);
  const quizId = quizRes.json('id');

  // Busca IDs das questões e primeira alternativa
  const questionsRes = http.get(`${BASE_URL}/quizzes/${quizId}/questions`, { headers: GET_HDR });
  const questions    = questionsRes.json();
  const questionId   = questions[0].id;

  return { courseId, moduleId, lessonId, quizId, questionId };
}

// ─── Cenários ─────────────────────────────────────────────────────────────────

function reads(d) {
  group('reads', () => {
    check(http.get(`${BASE_URL}/up`),
      { 'health 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/courses`, { headers: GET_HDR }),
      { 'courses index 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/courses/${d.courseId}`, { headers: GET_HDR }),
      { 'course show 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/courses/${d.courseId}/modules`, { headers: GET_HDR }),
      { 'modules index 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/modules/${d.moduleId}`, { headers: GET_HDR }),
      { 'module show 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/modules/${d.moduleId}/lessons`, { headers: GET_HDR }),
      { 'lessons index 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/lessons/${d.lessonId}`, { headers: GET_HDR }),
      { 'lesson show 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/modules/${d.moduleId}/quiz`, { headers: GET_HDR }),
      { 'quiz show 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/quizzes/${d.quizId}/questions`, { headers: GET_HDR }),
      { 'questions index 200': r => r.status === 200 });

    check(http.get(`${BASE_URL}/questions/${d.questionId}/alternatives`, { headers: GET_HDR }),
      { 'alternatives index 200': r => r.status === 200 });

    // Pendente pode ser 404 quando nenhuma geração foi solicitada ainda
    check(http.get(`${BASE_URL}/lessons/${d.lessonId}/conteudo-pendente`, { headers: GET_HDR }),
      { 'lesson pendente 2xx/404': r => r.status === 200 || r.status === 404 });

    check(http.get(`${BASE_URL}/modules/${d.moduleId}/quiz/pendente`, { headers: GET_HDR }),
      { 'quiz pendente 2xx/404': r => r.status === 200 || r.status === 404 });

    sleep(Math.random() * 0.3);
  });
}

function writes(_d) {
  group('writes', () => {
    const ts = `${Date.now()}${Math.floor(Math.random() * 9999)}`;

    // Fluxo: course → module → lesson → quiz → questão adicional → configurar quiz
    const cRes = http.post(
      `${BASE_URL}/courses`,
      JSON.stringify({ course: { title: `Curso k6 ${ts}`, category: 'Load', description: 'k6' } }),
      { headers: JSON_HDR },
    );
    if (!check(cRes, { 'create course 201': r => r.status === 201 })) return;
    const courseId = cRes.json('id');

    const mRes = http.post(
      `${BASE_URL}/courses/${courseId}/modules`,
      JSON.stringify({ modulo: { name: `Módulo k6 ${ts}` } }),
      { headers: JSON_HDR },
    );
    if (!check(mRes, { 'create module 201': r => r.status === 201 })) return;
    const moduleId = mRes.json('id');

    const lRes = http.post(
      `${BASE_URL}/modules/${moduleId}/lessons`,
      JSON.stringify({ lesson: { name: `Aula k6 ${ts}`, content_editor: 'Conteúdo k6 load test.' } }),
      { headers: JSON_HDR },
    );
    check(lRes, { 'create lesson 201': r => r.status === 201 });

    const quizRes = http.post(
      `${BASE_URL}/modules/${moduleId}/quiz`,
      JSON.stringify({
        quiz: {
          show_correct_answers: false,
          show_points: false,
          show_wrong_answers: false,
          questions_attributes: [
            {
              statement: `Questão k6 ${ts}`,
              points: 1,
              alternatives_attributes: [
                { text: 'Correta', correct: true  },
                { text: 'Errada',  correct: false },
              ],
            },
          ],
        },
      }),
      { headers: JSON_HDR },
    );
    if (!check(quizRes, { 'create quiz 201': r => r.status === 201 })) return;
    const quizId     = quizRes.json('id');

    // Questão extra via POST /quizzes/:id/questions
    const newQRes = http.post(
      `${BASE_URL}/quizzes/${quizId}/questions`,
      JSON.stringify({
        question: {
          statement: `Extra k6 ${ts}`,
          points: 2,
          alternatives_attributes: [
            { text: 'A certa', correct: true  },
            { text: 'A errada', correct: false },
          ],
        },
      }),
      { headers: JSON_HDR },
    );
    if (!check(newQRes, { 'create question 201': r => r.status === 201 })) return;
    const newQId = newQRes.json('id');

    // Alternativa extra via POST /questions/:id/alternatives
    const altRes = http.post(
      `${BASE_URL}/questions/${newQId}/alternatives`,
      JSON.stringify({ alternative: { text: `Alternativa extra k6 ${ts}`, correct: false } }),
      { headers: JSON_HDR },
    );
    check(altRes, { 'create alternative 201': r => r.status === 201 });

    // Configura o quiz recém-criado
    const cfgRes = http.post(
      `${BASE_URL}/quizzes/${quizId}/configurar`,
      JSON.stringify({ quiz: { show_correct_answers: true, show_points: true, show_wrong_answers: true } }),
      { headers: JSON_HDR },
    );
    check(cfgRes, { 'configurar quiz 200': r => r.status === 200 });

    sleep(Math.random() * 0.5);
  });
}

function ia(d) {
  group('ia', () => {
    // Gerar conteúdo da aula
    const gerarRes = http.post(
      `${BASE_URL}/lessons/${d.lessonId}/gerar-conteudo`,
      null,
      { headers: GET_HDR },
    );
    check(gerarRes, { 'gerar conteudo 200': r => r.status === 200 });

    // Ler pendente
    const pendenteRes = http.get(
      `${BASE_URL}/lessons/${d.lessonId}/conteudo-pendente`,
      { headers: GET_HDR },
    );
    check(pendenteRes, { 'conteudo pendente 200': r => r.status === 200 });

    // Confirmar (ou regerar — 50/50)
    if (Math.random() < 0.5) {
      const confirmarRes = http.post(
        `${BASE_URL}/lessons/${d.lessonId}/confirmar-conteudo`,
        null,
        { headers: GET_HDR },
      );
      check(confirmarRes, { 'confirmar conteudo 200': r => r.status === 200 });
    } else {
      const regenerarRes = http.post(
        `${BASE_URL}/lessons/${d.lessonId}/regerar-conteudo`,
        null,
        { headers: GET_HDR },
      );
      check(regenerarRes, { 'regerar conteudo 200': r => r.status === 200 });
    }

    // Gerar quiz AI
    const quizGerarRes = http.post(
      `${BASE_URL}/modules/${d.moduleId}/quiz/gerar`,
      JSON.stringify({ quantidade: 3 }),
      { headers: JSON_HDR },
    );
    check(quizGerarRes, { 'gerar quiz ai 200': r => r.status === 200 });

    // Pendente quiz
    const quizPendenteRes = http.get(
      `${BASE_URL}/modules/${d.moduleId}/quiz/pendente`,
      { headers: GET_HDR },
    );
    check(quizPendenteRes, { 'quiz pendente 200': r => r.status === 200 });

    // Confirmar quiz AI
    const quizConfirmarRes = http.post(
      `${BASE_URL}/modules/${d.moduleId}/quiz/confirmar`,
      null,
      { headers: GET_HDR },
    );
    check(quizConfirmarRes, { 'confirmar quiz ai 200': r => r.status === 200 });

    sleep(Math.random() * 0.2);
  });
}

// ─── Função principal ─────────────────────────────────────────────────────────

export default function (data) {
  const roll = Math.random();

  if (roll < 0.75) {
    reads(data);
  } else if (roll < 0.95) {
    writes(data);
  } else {
    ia(data);
  }
}
