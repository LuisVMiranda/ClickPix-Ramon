const transitions = {
  Created: ['AwaitingPayment', 'Canceled'],
  AwaitingPayment: ['Paid', 'Expired', 'Canceled'],
  Paid: ['Delivering', 'Refunded'],
  Delivering: ['Delivered', 'Refunded'],
  Delivered: ['Refunded'],
  Expired: ['AwaitingPayment'],
  Refunded: [],
  Canceled: []
};

export function canTransition(from, to) {
  return transitions[from]?.includes(to) ?? false;
}
