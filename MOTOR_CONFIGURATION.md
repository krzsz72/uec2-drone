# Konfiguracja Silników: Dron typu "Pusher" (Quad-X)

Ten plik opisuje docelową konfigurację silników i śmigieł dla drona w układzie Pusher (silniki zamontowane "do góry nogami", śmigła pod ramą pchające powietrze w dół).

## Układ Silników i Oznaczenia
Zgodnie z implementacją w pliku `rtl/motor_mixer.sv`, wyjścia `m1` do `m4` odpowiadają następującym pozycjom na ramie:

- **M1 (Przód-Lewo / FL):** Reaguje dodatnio na Roll (podnosi lewą stronę) i ujemnie na Pitch (opuszcza dziób).
- **M2 (Przód-Prawo / FR):** Reaguje ujemnie na Roll (opuszcza prawą stronę) i ujemnie na Pitch (opuszcza dziób).
- **M3 (Tył-Lewo / RL):** Reaguje dodatnio na Roll (podnosi lewą stronę) i dodatnio na Pitch (podnosi tył).
- **M4 (Tył-Prawo / RR):** Reaguje ujemnie na Roll (opuszcza prawą stronę) i dodatnio na Pitch (podnosi tył).

## Kierunki Obrotów i Śmigła (Widok z góry drona)
Ze względu na odwrócony montaż silników (Pusher), wektory momentów sił działają inaczej w odniesieniu do typowej orientacji silnika. 
Aby skręt drona w ośi Yaw działał poprawnie (dodatnie Yaw w mikserze = obrót w prawo / zgodnie z ruchem wskazówek zegara), silniki M1 i M4 przyspieszają, a M2 i M3 zwalniają. 
Oznacza to, że aby dron obrócił się w prawo, silniki M1 i M4 muszą generować moment obrotowy w prawo (zatem same muszą kręcić się w lewo, CCW).

**Patrząc na drona od GÓRY:**
1. **M1 (Przód-Lewo):** Kręci się w **LEWO (CCW)**. Wymaga śmigła typu "CCW" (odwróconego / pchającego), aby pchać powietrze w dół.
2. **M2 (Przód-Prawo):** Kręci się w **PRAWO (CW)**. Wymaga śmigła typu "CW" (standardowego).
3. **M3 (Tył-Lewo):** Kręci się w **PRAWO (CW)**. Wymaga śmigła typu "CW" (standardowego).
4. **M4 (Tył-Prawo):** Kręci się w **LEWO (CCW)**. Wymaga śmigła typu "CCW" (odwróconego / pchającego).

*Schemat:*
```text
      Przód Drona (Nose)
      
  (M1) \        / (M2)
  CCW   \      /   CW
         \    /
          |--|
          |  |
          |--|
         /    \
  (M3)  /      \  (M4)
   CW  /        \  CCW
   
       Tył (Tail)
```

## Podłączenie do Motor Mixera
Równania w `motor_mixer.sv` uwzględniają powyższą konfigurację Pusher:

- `M1 = Throttle - Pitch + Roll + Yaw`
- `M2 = Throttle - Pitch - Roll - Yaw`
- `M3 = Throttle + Pitch + Roll - Yaw`
- `M4 = Throttle + Pitch - Roll + Yaw`

Dzięki temu zmiana znaków przy `Yaw` (w porównaniu do standardowego drona) poprawnie uwzględnia fakt odwrotnych momentów obrotowych od silników skierowanych wałami w dół.
