// ********************************
//
//     TESTBENCH for gyro and spi dual work
//
//     Krzysztof Piziak
//
// ********************************

`timescale 1ns / 1ps

module gyro_spi_tb;

   // Sygnały testowe
   logic clk;
   logic [6:0] start;
   logic sclk;
   logic [103:0] reg_rx;
   logic poci;
   logic [103:0] reg_tx;
   logic copi;
   logic busy;
   logic done;
   logic cs_n;

   logic rst_n_gyro;
   logic rst_n_spi;
   logic gyro_data;
   logic begintick;
   logic [1:0] prev_state;
   logic [1:0] cur_state;

   // Instancjacja badanego modułu (DUT)
   spi_controller #(.WIDTH(104), .BYTEWIDTH(7)) dut_spi (
      .clk(clk),
      .rst_n(rst_n_spi), //!!!! przeniesc czyszczenie rejestrow wewnatrz spi
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

   gyro #(.WIDTH(104), .BYTEWIDTH(7)) dut_gyro (
      .rst_n(rst_n_gyro),
      .clk(clk),
      .d_length(start),
      .d_out(reg_tx),
      .gyro_data(gyro_data),
      .ready(done | begintick),
      .state_curr(cur_state),
      .state_prev(prev_state)
   );

   always @* begin
      gyro_data = reg_rx[1];
   end

   // Generacja zegara głównego 100 MHz (okres 10 ns)
   initial begin
      clk = 0;
      forever #5 clk = ~clk; 
   end

   // Główny blok stymulacji
   initial begin
      // Stan początkowy
      rst_n_gyro =1;
      begintick = 0;
      poci =0;
      $display("--- Rozpoczecie symulacji gyro+SPI ---");
      $display("Dane do wyslania (reg_tx): %h", reg_tx);

      // Odczekanie kilku cykli zegara (symulacja resetu układu)
      #25; 
      @(posedge clk);
      rst_n_gyro = 0;
      rst_n_spi = 0;
      @(posedge clk);
      rst_n_gyro = 1;
      rst_n_spi = 1;
     
      // Wystawienie sygnału startu na jeden cykl zegara
      @(posedge clk);
      begintick = 1;
      @(posedge clk);
      begintick = 0;
      
      // Generowanie losowych danych na linii POCI podczas trwania transmisji
      // Symulujemy odpowiedź od urządzenia slave
      fork
         begin
            // Nasłuchiwanie na flagę zakończenia transmisji
            wait(done);
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
      // Faza STARTUP - przechodzimy przez 6 konfiguracji początkowych
        wait(done); $display("Wyslano init 0 (reg_tx: %h)", reg_tx); #25;
        wait(done); $display("Wyslano init 1 (reg_tx: %h)", reg_tx); #25;
        wait(done); $display("Wyslano init 2 (reg_tx: %h)", reg_tx); #25;
        wait(done); $display("Wyslano init 3 (reg_tx: %h)", reg_tx); #25;
        wait(done); $display("Wyslano init 4 (reg_tx: %h)", reg_tx); #25;
        wait(done); $display("Wyslano init 5 (reg_tx: %h)", reg_tx); #25;

      wait(done);
      #25;
      for(int i = 0; i<16;i++) begin
               automatic logic [15:0] data_in = 16'b010;
               @(posedge sclk);
               poci = data_in[15-i]; 
            end
      wait(cs_n);
      #60;
      if(reg_tx=={1'b1,7'h22,96'b0})begin
         for(int i = 0; i<104;i++) begin
               automatic logic [103:0] data_in = {8'h0,16'h1234,16'h5678,16'h9abc,16'hdef0,16'h1234,16'h5678};
               @(posedge sclk);
               poci = data_in[103-i]; 
            end
         end
      #1010ns assign poci = 1'b0;
      wait(done);
      #25;
       wait(done);
      #25;
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