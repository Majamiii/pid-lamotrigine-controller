pkg load control;
pkg load signal;

%Parametri modela
k = 1;
ke = 0.025;
ka = 1;
V = 80;
alfa = 5;

%Vreme
t = 0:0.1:300;

%Mirna radna tacka
x10 = 0.05;
x20 = 0.025;
u0 = 0.067;

%Pocetne vrednosti
x0 = [x10; x20];

%Definicija ulaza kao step signal
delta_u = 0.01;
u = @(t) u0 + delta_u * (t >= 10);

%Nelinearni sistem
f_nl = @(t, x)[-ka*x(1) + (k*u(t))/(1 + alfa*u(t));(ka/V)*x(1) - ke*x(2)];
[t, x_nelin] = ode45(f_nl, t, x0);

%Linearizovani model
A = [-ka, 0; ka/V, -ke];

B = [k / (1 + alfa * u0)^2; 0];

C = [0, 1];

D = 0;

sys = ss(A, B, C, D);

%Simulacija linearnog modela na pobudu delta_u
ulaz_lin = zeros(size(t));
ulaz_lin(t>=10) = delta_u;

%Odziv linearnog modela
y_lin = lsim(sys, ulaz_lin, t, [0 0]) + x20;

%Prikaz rezultata
figure;
plot(t, x_nelin(:,2), 'b', 'LineWidth', 1);
hold on;
plot(t, y_lin, 'r--');
xlabel('Vreme [h]');
ylabel('Koncentracija Cp [mmol/L]');
title('Poredjenje nelinearnog i linearizovanog modela');
legend('Nelinearni model', 'Linearni model');
grid on;









