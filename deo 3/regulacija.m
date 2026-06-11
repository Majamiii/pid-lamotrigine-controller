clear all;
clc;
close all;

pkg load control

% funkcija prenosa modela pacijanta i biosenzora
s = tf('s');
G = 0.0125 / ((s + 1) * (s + 0.025));
H = 1;


% -------- PROJEKTOVANJE PI REGULATORA ------------
% Naš objekat ima spor pol na s = -0.025.
% Biramo nulu regulatora (Ki/Kp) tako da je postavimo tačno na -0.025
% kako bismo skratili taj spori pol i drastično ubrzali sistem.
% G_reg(s) = Kp * (s + 0.025) / s

% ali funkciju prenosa regulatora simuliramo bez pojacanja

G_reg = (s + 0.025) / s;
G0 = G_reg * G * H; % Povratni prenos

% ----------- GMK --------------
figure(1);
rlocusx(G0);
title('GMK sa PI regulatorom');
grid on;

% ------------- BIRANJE POJAVANJA Kp ---------------

% Analitički ili očitavanjem sa grafika biramo Kp tako da sistem bude brz,
% ali bez prevelikog preskakanja. Uzmimo npr. Kp = 40 za stabilan i brz odziv.
Kp = 40;
Ki = Kp * 0.025; % Pošto smo izabrali Ki/Kp = 0.025

fprintf('\nIzabrani parametri regulatora:\n');
fprintf('Kp = %f\n', Kp);
fprintf('Ki = %f\n', Ki);

% Konačna funkcija prenosa PI regulatora
G_reg = Kp + (Ki / s);



% funkcija prenosa zatvorenog sistema

% funkcija spregnutog prenosa od reference R(s) do izlaza Y(s)
W_s = feedback(G_reg * G, H);

% funkcija prenosa od poremećaja D(s) do izlaza Y(s)
% poremećaj se sabira na ulazu u objekat (između regulatora i G)
W_d = feedback(G, G_reg * H);



% --------- SIMULACIJA ------------

% referenca i vreme simulacije
r0 = 0.025;
t = 0:0.1:300; % 0 do 300 sekundi

% Odziv sistema na referentni step signal (Doziranje leka implantatom)
y_ref = r0 * step(W_s, t);

% modelovanje poremećaja koji se dešava kasnije (u trenutku t = 200s)
% amplituda poremećaja d0 (promena apsorpcije leka za 0.005)
d0 = 0.005;
t_poremecaja = 200;

% generisanje odziva na poremecaj
y_poremecaj_osnovni = d0 * step(W_d, t);
y_poremecaj_pomeren = zeros(size(t));

% primena vremenskog kašnjenja za poremećaj u t = 200s
for i = 1:length(t)
    if t(i) >= t_poremecaja
        % tražimo indeks koji odgovara vremenu t(i) - t_poremecaja
        [~, idx] = min(abs(t - (t(i) - t_poremecaja)));
        y_poremecaj_pomeren(i) = y_poremecaj_osnovni(idx);
    end
end

% ukupni odziv sistema
y_ukupno = y_ref + y_poremecaj_pomeren;


% -------- CRTANJE GRAFIKA ----------

figure(2);
plot(t, y_ukupno, 'b', 'LineWidth', 2);
hold on;

% Iscrtavanje granica terapijskog opsega radi provere bezbednosti
plot(t, 0.02 * ones(size(t)), 'r--', 'LineWidth', 1.5);
plot(t, 0.03 * ones(size(t)), 'r--', 'LineWidth', 1.5);
plot(t, 0.025 * ones(size(t)), 'g:');

% Obeležavanje trenutka kada nastupa poremećaj
line([t_poremecaja t_poremecaja], [0.01 0.04], 'Color', 'm', 'LineStyle', '-.');

title('Kontinuirano praćenje koncentracije Lamotrigina u krvi pacijenta');
xlabel('Vreme [s]');
ylabel('Koncentracija Cp [mmol/L]');
legend('Koncentracija leka', 'Donja granica (0.02)', 'Gornja granica (0.03)', 'Referenca (0.025)', 'Trenutak poremećaja', 'Location', 'SouthEast');
grid on;
axis([0 300 0.015 0.035]);

% Provera statičke greške u komandnom prozoru
fprintf('\nKonačna vrednost koncentracije (t->inf): %f mmol/L\n', y_ukupno(end));


% ----- PRESKOK ------
y_preskok = max(y_ukupno)
fprintf('Najveca vrednost koncentracije lamotrigina je: ', y_preskok, '\n')
fprintf('Preskok je: ', (y_preskok - 0.025)/0.025*100, '%\n\n')

