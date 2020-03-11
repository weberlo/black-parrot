/*
 * bp_fe_bht_global_simple.v
 *
 * Branch History Table (BHT) records the information of the branch history, i.e.
 * branch taken or not taken.
 * Each entry consists of 2 bit saturation counter. If the counter value is in
 * the positive regime, the BHT predicts "taken"; if the counter value is in the
 * negative regime, the BHT predicts "not taken". The implementation of BHT is
 * native to this design.
 * TODO(gus) update this description
 */
module bp_fe_bht_global_simple
  import bp_fe_pkg::*;
   #(parameter global_history_length_p

     , localparam saturation_size_lp = 2
     , localparam els_lp             = 2**global_history_length_p
     )
   (input                         clk_i
    , input                       reset_i

    , input                       w_v_i
    , input [global_history_length_p-1:0] history_w_i
    // What direction the branch went (needed for history table)
    , input                       actual_i
    , input                       correct_i

    , input                       r_v_i
    // Metadata: the history for this prediction.
    // This metadata makes it back to the BHT via history_w_i.
    ,        output  [global_history_length_p-1:0] history_r_o
    , output                      predict_o
    );

   logic [global_history_length_p-1:0]       global_history_r, global_history_n;
   assign global_history_n = {global_history_r[global_history_length_p-2:0], actual_i};
   assign history_r_o = global_history_n;

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          global_history_r <= 0;
        else
          // Have to figure out what the actual prediction history was.
          // That's hard, given that we only have whether or not it was
          // correct!
          // We can add another metadata field.
          // TODO(gus) How much delay is there in updating the history? How
          // much does this affect results?
          global_history_r <= global_history_n;
     end

   logic [els_lp-1:0][saturation_size_lp-1:0] mem;

   assign predict_o = r_v_i ? mem[global_history_n][1] : 1'b0;

   always_ff @(posedge clk_i)
     if (reset_i)
       mem <= '{default:2'b01};
     else if (w_v_i)
       begin
          //2-bit saturating counter(high_bit:prediction direction,low_bit:strong/weak prediction)
          case ({correct_i, mem[history_w_i][1], mem[history_w_i][0]})
            //wrong prediction
            3'b000: mem[history_w_i] <= {mem[history_w_i][1]^mem[history_w_i][0], 1'b1};//2'b01
            3'b001: mem[history_w_i] <= {mem[history_w_i][1]^mem[history_w_i][0], 1'b1};//2'b11
            3'b010: mem[history_w_i] <= {mem[history_w_i][1]^mem[history_w_i][0], 1'b1};//2'b11
            3'b011: mem[history_w_i] <= {mem[history_w_i][1]^mem[history_w_i][0], 1'b1};//2'b01
            //correct prediction
            3'b100: mem[history_w_i] <= mem[history_w_i];//2'b00
            3'b101: mem[history_w_i] <= {mem[history_w_i][1], ~mem[history_w_i][0]};//2'b00
            3'b110: mem[history_w_i] <= mem[history_w_i];//2'b10
            3'b111: mem[history_w_i] <= {mem[history_w_i][1], ~mem[history_w_i][0]};//2'b10
          endcase
       end

endmodule
