const request = require('supertest');
const app = require('../src/app');

describe('Routes', () => {
    test('GET / retourne un message', async() => {
        const res = await request(app).get('/');
        expect(res.status).toBe(200);
        expect(res.body.message).toContain('DevSecOps');
    });

    test('GET /health retourne status ok', async() => {
        const res = await request(app).get('/health');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('ok');
    });
});