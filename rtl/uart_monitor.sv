`timescale 1ns / 1ps

module uart_monitor (
        input  logic clk,
        input  logic rx,
        output logic tx,
        input  logic loopback_enable,
        output logic rx_monitor,
        output logic tx_monitor
    );

    // Ciągłe przypisanie dla sygnału tx
    // Jeśli loopback_enable == 1, tx powiela rx. W przeciwnym razie tx = 0.
    assign tx = (loopback_enable == 1'b1) ? rx : 1'b0;

    // Przerzutniki buforujące (odświeżane na narastającym zboczu zegara)
    always_ff @(posedge clk) begin
        rx_monitor <= rx;
        tx_monitor <= tx; // Odczytujemy i buforujemy aktualny stan linii wyjściowej tx
    end

endmodule