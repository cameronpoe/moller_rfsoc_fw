`timescale 1ns / 1ps

module adc_packetizer #(
    parameter HEADER_WORDS = 2
)(
    input aclk,
    input aresetn,
    
    input [31:0] words_per_packet,
    
    input [63:0] s_axis_tdata,
    input s_axis_tvalid,
    output reg s_axis_tready,
    input s_axis_tlast,
    input s_axis_tuser,
        
    output reg [63:0] m_axis_tdata,
    output reg m_axis_tvalid, 
    output reg m_axis_tlast, 
    input m_axis_tready
    );
        
    reg [$clog2(HEADER_WORDS):0] header_counter = 0;
    reg [31:0] word_counter = 32'd0; 
    
    reg [63:0] packet_ts = 64'd0;
        
    always @(posedge aclk) begin
        if (aresetn == 1'b0 | m_axis_tready == 1'b0) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            s_axis_tready <= 1'b0;
            header_counter <= 0; 
            word_counter <= 32'd0;
        end else begin
            if (header_counter == 0 && word_counter == 0) begin
                s_axis_tready <= 1'b1;
            end
            
            if (header_counter == 0 && s_axis_tready == 1'b1 && s_axis_tvalid == 1'b1) begin
                if (s_axis_tuser == 1'b0)
                    header_counter <= 0;
                else begin
                    packet_ts <= s_axis_tdata;
                    header_counter <= header_counter + 1;
                    s_axis_tready <= 1'b0;
                    m_axis_tdata <= 64'hFFFFFFFFFFFFFFFF; // denotes packet begins
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b0;
                end
            end else if (header_counter > 0 && header_counter < HEADER_WORDS && word_counter == 0) begin
                if (header_counter == HEADER_WORDS-1) begin
                    m_axis_tdata <= packet_ts;
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b0;
                    header_counter <= header_counter + 1;
                    s_axis_tready <= 1'b1;
                end
            end else if (header_counter == HEADER_WORDS && word_counter < words_per_packet - HEADER_WORDS && s_axis_tready == 1'b1 && s_axis_tvalid == 1'b1 && s_axis_tuser == 1'b0) begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= 1'b1;
                if (word_counter < words_per_packet - HEADER_WORDS - 1) begin
                    m_axis_tlast <= 1'b0;
                    word_counter <= word_counter + 1;
                end
                else if (word_counter == words_per_packet - HEADER_WORDS - 1) begin
                    m_axis_tlast <= 1'b1;
                    word_counter <= 0;
                    header_counter <= 0;
                end
            end else begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end    
        end
    end       
endmodule
