function t_qp_threshold = generate_QP()

mu = 2.5; % s
t_qp_threshold = exprnd(mu);

% Clamp the ITI to [0.5 10]
t_qp_threshold = min([t_qp_threshold, 5]);
t_qp_threshold = max([1 t_qp_threshold]); 