function iti = generate_iti()

mu = 3; % s
iti = exprnd(mu);

% Clamp the ITI to [0.5 10]
iti = min([iti, 10]);
iti = max([0.5 iti]); 