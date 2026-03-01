import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const contractPath = path.resolve(__dirname, '../../../docs/contracts/order_status_transitions.v1.json');
const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

const transitions = contract.transitions;

export function canTransition(from, to) {
  return transitions[from]?.includes(to) ?? false;
}

export function getOrderStatusContract() {
  return contract;
}
