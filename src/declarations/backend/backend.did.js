export const idlFactory = ({ IDL }) => {
  return IDL.Service({
    'deposit' : IDL.Func([IDL.Nat], [IDL.Bool], []),
    'getBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getTransactionHistory' : IDL.Func(
        [IDL.Principal],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Int, IDL.Int))],
        ['query'],
      ),
    'init' : IDL.Func([], [], []),
    'withdraw' : IDL.Func([IDL.Nat], [IDL.Bool], []),
  });
};
export const init = ({ IDL }) => { return []; };
