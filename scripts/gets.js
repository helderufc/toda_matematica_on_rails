/**
 * k6 GET-only Load Test — Toda Matemática API
 *
 * Perfil de carga:
 *   20s → sobe p/ 133 VUs (aquecimento)
 *   30s → sustenta 133 VUs (estado estável)
 *   20s → sobe p/ 2700 VUs (pico)
 *   20s → sustenta 2700 VUs
 *   20s → volta p/ 133 VUs (recuperação)
 *   10s → vai p/ 0 (desaquecimento)
 *
 * Variáveis de ambiente:
 *   BASE_URL   (default: http://localhost:3000)
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

const GET_HDR  = { Accept: 'application/json' };
const JSON_HDR = { 'Content-Type': 'application/json', Accept: 'application/json' };

// ─── Perfil de carga ──────────────────────────────────────────────────────────

export const options = {
  stages: [
    { duration: '20s', target: 133  },  // aquecimento
    { duration: '30s', target: 133  },  // estado estável
    { duration: '20s', target: 2700 },  // subida ao pico
    { duration: '20s', target: 2700 },  // sustentação do pico
    { duration: '20s', target: 133  },  // recuperação
    { duration: '10s', target: 0    },  // desaquecimento
  ],
  thresholds: {
    http_req_failed:                    ['rate<0.01'],
    http_req_duration:                  ['p(95)<500', 'p(99)<1500'],
    'http_req_duration{group:::reads}': ['p(95)<300'],
  },
};

// ─── Setup: cria dados base para as leituras ──────────────────────────────────

export function setup() {
  const ts = Date.now();

  const cRes = http.post(
    `${BASE_URL}/courses`,
    JSON.stringify({ course: { title: `k6 Gets ${ts}`, category: 'Load', description: 'Setup k6 gets.' } }),
    { headers: JSON_HDR },
  );
  if (cRes.status !== 201) throw new Error(`setup POST /courses falhou ${cRes.status}: ${cRes.body}`);
  const courseId = cRes.json('id');

  const mRes = http.post(
    `${BASE_URL}/courses/${courseId}/modules`,
    JSON.stringify({ modulo: { name: `Módulo Setup ${ts}` } }),
    { headers: JSON_HDR },
  );
  if (mRes.status !== 201) throw new Error(`setup POST /courses/${courseId}/modules falhou`);
  const moduleId = mRes.json('id');

  const lRes = http.post(
    `${BASE_URL}/modules/${moduleId}/lessons`,
    JSON.stringify({ lesson: { name: `Aula Setup ${ts}`, content_editor: 'Conteúdo de setup k6.' } }),
    { headers: JSON_HDR },
  );
  if (lRes.status !== 201) throw new Error(`setup POST /modules/${moduleId}/lessons falhou`);
  const lessonId = lRes.json('id');

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
        ],
      },
    }),
    { headers: JSON_HDR },
  );
  if (quizRes.status !== 201) throw new Error(`setup POST /modules/${moduleId}/quiz falhou`);
  const quizId = quizRes.json('id');

  const questionsRes = http.get(`${BASE_URL}/quizzes/${quizId}/questions`, { headers: GET_HDR });
  const questionId   = questionsRes.json()[0].id;

  return { courseId, moduleId, lessonId, quizId, questionId };
}

// ─── Função principal: apenas leituras ───────────────────────────────────────

export default function (d) {
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

    sleep(Math.random() * 0.3);
  });
}
