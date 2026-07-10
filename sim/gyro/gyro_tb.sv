// ********************************
//
//     TESTBENCH for gyroscope
//
//     Krzysztof Piziak
//
// ********************************

`timescale 1ns / 1ps

module gyro_tb;

   // Sygnały testowe
   logic clk;
   logic ready;
   logic rst_n;
   logic [5:0] d_length;
   logic [55:0] d_out;
   logic gyro_data;

   // Instancjacja badanego modułu (DUT)
   gyro #(.WIDTH(56)) dut (
      .rst_n(rst_n),
      .clk(clk),
      .ready(ready),
      .d_length(d_length),
      .d_out(d_out),
      .gyro_data(gyro_data)
   );

   // Generacja zegara głównego 100 MHz (okres 10 ns)
   initial begin
      clk = 0;
      forever #5 clk = ~clk; 
   end

   // Główny blok stymulacji
   initial begin
      // Stan początkowy
      ready = 0;
      gyro_data = 0;
      $display("--- Rozpoczecie symulacji gyro ---");
     
      // Odczekanie kilku cykli zegara (symulacja resetu układu)
      rst_n =1;
      #25; 
      @(posedge clk);
      rst_n=0;
      @(posedge clk);
      rst_n=1;
      // Wystawienie sygnału startu na jeden cykl zegara
     for(int i=0; i<3; i++)begin    
         @(posedge clk);
         ready = 1;
         @(posedge clk);
         ready = 0;
         #100;
     end
      gyro_data = 1;
       @(posedge clk);
      ready = 1;
      @(posedge clk);
      ready = 0;
      #60;
      gyro_data =0;
      #60;
      @(posedge clk);
      ready = 1;
      @(posedge clk);
      ready = 0;
      // Odczekanie i wyświetlenie wyników
      #20;
      $display("Transmisja zakonczona!");
      
      // Zakończenie symulacji
      $finish;
   end

   // Monitorowanie zmian na linii COPI (MOSI)
   initial begin
      $monitor("Czas: %0t ns | d_length: %d | d_out (Wyslane): %b", $time, d_length, d_out);
   end

endmodule