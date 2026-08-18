// ********************************
//
//     TESTBENCH for SPI_controller
//
//     Krzysztof Piziak
//
// ********************************

`timescale 1ns / 1ps

module spi_controller_tb;

   // Sygnały testowe
   logic clk;
   logic [5:0] start;
   logic sclk;
   logic [55:0] reg_rx;
   logic poci;
   logic [55:0] reg_tx;
   logic copi;
   logic busy;
   logic done;
   logic cs_n;
   logic rst_n;

   // Instancjacja badanego modułu (DUT)
   spi_controller #(.WIDTH(56), .BYTEWIDTH(6)) dut (
      .clk(clk),
      .rst_n(rst_n),
      .d_length(start),             
      .sclk(sclk),
      .reg_rx(reg_rx),
      .poci(poci),
      .reg_tx(reg_tx),
      .copi(copi),
      .busy(busy),
      .done(done),
      .cs_n(cs_n)
   );

   // Generacja zegara głównego 100 MHz (okres 10 ns)
   initial begin
      clk = 0;
      forever #5 clk = ~clk; 
   end

   // Główny blok stymulacji
   initial begin
      // Stan początkowy
      start = 0;
      poci = 0;
      reg_tx = 16'h6E00; // Wartość do wysłania (binarnie: 01101110)
      
      $display("--- Rozpoczecie symulacji SPI ---");
      $display("Dane do wyslania (reg_tx): %h", reg_tx);

      // Odczekanie kilku cykli zegara (symulacja resetu układu)
      #25; 
      @(posedge clk);
      rst_n = 0;
      @(posedge clk);
      rst_n = 1;
     
      // Wystawienie sygnału startu na jeden cykl zegara
      @(posedge clk);
      start = 16;
      
      // Generowanie losowych danych na linii POCI podczas trwania transmisji
      // Symulujemy odpowiedź od urządzenia slave
      fork
         begin
            // Nasłuchiwanie na flagę zakończenia transmisji
            wait(done);
            start=0;
         end
         begin
            // Podawanie danych na MISO na narastającym zboczu SCLK
            for(int i = 0; i<16;i++) begin
               automatic logic [15:0] data_in = 16'h006c;
               @(posedge sclk);
               poci = data_in[15-i]; 
            end
         end
      join
      #25
      @(posedge clk);
      start = 56;
      
      wait(done);
      start=0;
      

      // Odczekanie i wyświetlenie wyników
      #20;
      $display("Transmisja zakonczona!");
      $display("Odebrane dane (reg_rx): %h", reg_rx);
      
      // Zakończenie symulacji
      $finish;
   end

   // Monitorowanie zmian na linii COPI (MOSI)
   initial begin
      $monitor("Czas: %0t ns | SCLK: %b | COPI (Wyslane): %b | POCI (Odebrane): %b", $time, sclk, copi, poci);
   end

endmodule