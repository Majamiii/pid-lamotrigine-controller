pkg load control;
pkg load signal;


clear all;
clc;
close all;


% ------------------- LINEARIZACIJA ------------------------




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


% prebacivanje LTI u funkciju prenosa kako bi je lakse spojili sa regulatorom
G = tf(sys)


% ------------------ REGULACIJA ----------------------


% funkcija prenosa modela pacijanta i biosenzora
s = tf('s');
G_delta = 0.0125 / ((s + 1) * (s + 0.025))
H = 1;

% G = tf(sys) je ekvivalentno funkciji prenosa G = 0.0125 / ((s + 1) * (s + 0.025)) datoj u zadatku

%    ؀
%    Transfer function 'G' from input 'u1' to output ...
%
%                0.007014
%    y1:  ---------------------
%        s^2 + 1.025 s + 0.025
%
%    Continuous-time model.
%
%    Transfer function 'G_delta' from input 'u1' to output ...
%
%                0.0125
%    y1:  ---------------------
%        s^2 + 1.025 s + 0.025
%

% -------- PROJEKTOVANJE PI REGULATORA ------------
% Naš objekat ima spor pol na s = -0.025.
% Biramo nulu regulatora (Ki/Kp) tako da je postavimo tačno na -0.025
% kako bismo skratili taj spori pol i drastično ubrzali sistem.
% G_reg(s) = Kp * (s + 0.025) / s

% ali funkciju prenosa regulatora simuliramo bez pojacanja

G_reg = (s + 0.025) / s;
G0 = G_reg * G * H; % Povratni prenos


% ------------- BIRANJE POJAVANJA Kp ---------------

% Sa GMK grafika biramo Kp tako da zatvoreni sistem ima pozeljne karakteristike.
% Cilj je blaga oscilatornost bez prevelikog preskoka.

% Biramo se Kp = 40 -> preskok je oko 5%, sto je dovoljno brzo i dovoljno sigurno

Kp = 40;
Ki = Kp * 0.025; % Pošto smo izabrali Ki/Kp = 0.025


% ----------- GMK --------------
figure(1);
rlocusx(G0);
title('GMK sa PI regulatorom');
grid on;

fprintf('\nIzabrani parametri regulatora:\n');
fprintf('Kp = %f\n', Kp);
fprintf('Ki = %f\n', Ki);


% Konačna funkcija prenosa PI regulatora
G_reg = Kp + (Ki / s);


% funkcija povratnog prenosa
G1 = G_reg * G;

% ------- NIKVIST ----------
nyquist(G1);grid on;

% ------- PRETECI ----------
% [d,fi,Wpi,Wpf] = margin(G1); margin(G1);grid on;



% funkcija prenosa zatvorenog sistema

% funkcija spregnutog prenosa od reference R(s) do izlaza Y(s)
W_s = feedback(G_reg * G, H);

% funkcija prenosa od poremećaja D(s) do izlaza Y(s)
% poremećaj se sabira na ulazu u objekat (između regulatora i G nakon linearizacije)
W_d = feedback(G, G_reg * H);



% --------- SIMULACIJA ------------

% referenca i vreme simulacije
r0 = 0.025;
t = 0:0.1:400; % 0 do 400 sekundi

% odziv sistema na referentni step signal (doziranje leka)
y_ref = r0 * step(W_s, t);

% modelovanje poremećaja koji se dešava kasnije (u trenutku t = 200s)
% amplituda poremećaja d0 (promena apsorpcije leka za 0.005)
d0 = 0.005;
t_poremecaja = 200;

d = zeros(size(t));
d(t >= 200) = d0;

y_poremecaj = lsim(W_d, d, t);

% ukupni odziv sistema
y_ukupno = y_ref + y_poremecaj;


% -------- CRTANJE GRAFIKA ----------
figure(2);
clf;
hold on;
p1 = plot(t, y_ukupno, 'b', 'LineWidth', 1, 'DisplayName', 'Koncentracija leka');
hold on;
p2 = plot(t, 0.02 * ones(size(t)), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Donja granica (0.02)');
p3 = plot(t, 0.03 * ones(size(t)), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Gornja granica (0.03)');
p4 = plot(t, 0.025 * ones(size(t)), 'g:', 'DisplayName', 'Referenca (0.025)');
p5 = plot([t_poremecaja t_poremecaja], [0.01 0.04], 'm-.', 'LineWidth', 1.2, 'DisplayName', 'Trenutak poremećaja');

legend('show');

grid on;
axis([0 400 0.015 0.035]);

% provera greske u ustaljenom stanju
fprintf('\nKonačna vrednost koncentracije (t->inf): %f mmol/L\n', y_ukupno(end));


% ----- PRESKOK ------
y_preskok = max(y_ukupno(:))
fprintf('Najveca vrednost koncentracije lamotrigina je: %.6e\n', y_preskok);
fprintf('Preskok je: %.2f%%\n', (y_preskok - 0.025)/0.025*100);

