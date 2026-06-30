# Automatic Control of Antiepileptic Drug Concentration in Blood

**Course project — Automatic Control Systems**
Authors: Jovana Vranješević (RA14/2024), Maja Milović (RA69/2024)

## Overview

This project explores the design of a **closed-loop control system** for automatically regulating the blood concentration of **lamotrigine**, an antiepileptic drug used in the treatment of epilepsy and bipolar disorder. The goal is to keep the plasma concentration within the therapeutic range of **0.02–0.03 mmol/L**, where the drug is effective but not toxic.

The system is conceived as analogous to closed-loop insulin pumps used in diabetes management: a subcutaneous infusion pump doses the drug, a biosensor continuously measures its blood concentration, and a controller adjusts the dosing rate in real time based on the measured feedback.

## System Architecture

The control loop consists of four main components:

- **Sensor (biosensor):** measures the current lamotrigine concentration in blood plasma.
- **Controller:** compares the measured concentration to the reference (target) value and computes the required control action.
- **Actuator (infusion pump):** subcutaneously delivers the drug according to the controller's command.
- **Plant (the human body):** absorbs, distributes, and eliminates the drug, producing the measurable blood concentration.

### Block Diagram

<img width="948" height="307" alt="Screenshot 2026-06-30 152422" src="https://github.com/user-attachments/assets/b124786e-1ff1-43af-af90-b2adb63fcb84" />


**Signal definitions:**
- `r(t)` — reference signal (desired concentration)
- `e(t) = r(t) − ym(t)` — error signal
- `u(t)` — control signal (drug dosing rate)
- `y(t)` — actual plant output (true plasma concentration)
- `ym(t)` — measured concentration (sensor output)
- `d(t)` — disturbance (physiological factors independent of the pump)

## Mathematical Model

The drug dynamics are described by a nonlinear two-state model:

- **Subcutaneous depot dynamics:** rate of change of drug amount in the depot, driven by absorption and pump input (with a saturation nonlinearity in the pump characteristic).
- **Plasma concentration dynamics:** driven by absorption from the depot and first-order elimination from the blood.

The model is **linearized** around a working point near the middle of the therapeutic range (Cp* ≈ 0.025 mmol/L), yielding a linear state-space representation (matrices A, B, C, D). Simulations confirm that the linearized model closely matches the nonlinear model for small input deviations around the working point.

## Controller Design

Starting from the linearized plant transfer function, two controller structures were evaluated:

- **P controller:** Stable for all positive gains, but **cannot eliminate steady-state error**, since the plant has no integrator (no astatism). Unacceptable for precise therapeutic dosing.
- **PI controller:** Adds integral action, **eliminating steady-state error** both for reference tracking and disturbance rejection. The controller zero is placed to cancel the plant's slow pole, simplifying the open-loop dynamics to a standard second-order system.
- **PID controller:** Considered but **rejected** — the derivative term would amplify biosensor measurement noise, risking unsafe, abrupt dosing changes.

Using the root locus method and targeting a damping ratio ζ ≈ 0.707 (a good trade-off between response speed and overshoot), the final PI parameters were selected as:

```
Kp = 40,  Ki = 1
```

### Simulation Results

With these parameters, the closed-loop system:
- Reaches the reference concentration (0.025 mmol/L) quickly, with an overshoot of about 4.8%.
- Stays within the safe therapeutic bounds (0.02–0.03 mmol/L) throughout the transient.
- Rejects an external disturbance introduced at t = 200 s, returning to the reference value with zero steady-state error thanks to the integral action.

- <img width="817" height="573" alt="Screenshot 2026-06-30 152633" src="https://github.com/user-attachments/assets/273eb784-4f28-49a9-b0f4-8f59d4d77285" />
## Stability Analysis (Nyquist Criterion)

The open-loop transfer function of the linearized system with the designed controller is:

```
W(s) = 0.25 / (s(s + 1))
```

- The plant has no unstable poles (P = 0), and the Nyquist plot never encircles the critical point (−1, j0), confirming closed-loop stability.
- **Gain margin:** effectively infinite (the phase curve never crosses −180°).
- **Phase margin:** 74.85°
- **Delay margin:** 4.83 s

  <img width="992" height="827" alt="nikvist" src="https://github.com/user-attachments/assets/5ba809c0-de55-4600-988a-8ecd42581824" />


These large stability margins confirm that the chosen PI controller parameters are robust.

## Tools Used

- **GNU Octave** for linearization, root locus (`rlocus`), closed-loop simulation, Bode and Nyquist plot generation.

## Repository Contents

| File | Description |
|---|---|
| `SAU projekat - regulacija lamotrigina - Jovana Vranješević i Maja Milović.pdf` / project document | Full project report (system description, modeling, linearization, controller design, stability analysis) |
| Octave scripts | Linearization, root locus, time-domain simulation, Bode/Nyquist analysis |
