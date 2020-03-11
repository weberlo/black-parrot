/*
 * bp_fe_bht.v
 *
 * Branch History Table (BHT) records the information of the branch history, i.e.
 * branch taken or not taken.
 * Each entry consists of 2 bit saturation counter. If the counter value is in
 * the positive regime, the BHT predicts "taken"; if the counter value is in the
 * negative regime, the BHT predicts "not taken". The implementation of BHT is
 * native to this design.
*/
module bp_fe_bht
 import bp_fe_pkg::*;
 #( parameter bht_idx_width_p = "inv"
  , localparam saturation_size_p = 4

   , localparam els_lp             = 2**bht_idx_width_p
   )
  (input                         clk_i
   , input                       reset_i

   , input                       w_v_i
   , input [bht_idx_width_p-1:0] idx_w_i
   , input                       correct_i

   , input                       r_v_i
   , input [bht_idx_width_p-1:0] idx_r_i
   , output                      predict_o
   );

logic [els_lp-1:0][saturation_size_p-1:0] mem;

assign predict_o = r_v_i ? mem[idx_r_i][saturation_size_p-1] : 1'b0;

always_ff @(posedge clk_i)
  if (reset_i)
    mem <= '{ default : { 1'b0, {(saturation_size_p-1){1'b1}} } };
  else if (w_v_i)
    begin
      //2-bit saturating counter(high_bit:prediction direction,low_bit:strong/weak prediction)
      case ({correct_i, mem[idx_w_i][saturation_size_p-1]})
        //wrong prediction
        2'b00: mem[idx_w_i] <= mem[idx_w_i] + 1;
        2'b01: mem[idx_w_i] <= mem[idx_w_i] - 1;
        //correct prediction
        2'b10: mem[idx_w_i] <= (mem[idx_w_i] == {saturation_size_p{1'b0}}) ? mem[idx_w_i] : mem[idx_w_i] - 1;
        2'b11: mem[idx_w_i] <= (mem[idx_w_i] == {saturation_size_p{1'b1}}) ? mem[idx_w_i] : mem[idx_w_i] + 1;
      endcase
    end

endmodule
