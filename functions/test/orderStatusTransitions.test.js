import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { canTransition, getOrderStatusContract } from '../src/orders/statusMachine.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const contractPath = path.resolve(__dirname, '../../docs/contracts/order_status_transitions.v1.json');
const contractFromFile = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

test('status machine uses canonical contract file', () => {
  assert.deepEqual(getOrderStatusContract(), contractFromFile);
});

test('all allowed and forbidden edges match contract', () => {
  const { states, transitions } = contractFromFile;

  for (const from of states) {
    const allowed = new Set(transitions[from] ?? []);

    for (const to of states) {
      const actual = canTransition(from, to);
      const expected = allowed.has(to);
      assert.equal(actual, expected, `edge ${from} -> ${to} should be ${expected}`);
    }
  }
});
