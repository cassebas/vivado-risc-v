library ieee;
use ieee.std_logic_1164.all;


entity blk_mem_gen_1 is
  port (clka : in STD_LOGIC;
        wea : in STD_LOGIC_VECTOR ( 3 downto 0 );
        addra : in STD_LOGIC_VECTOR ( 13 downto 0 );
        dina : in STD_LOGIC_VECTOR ( 31 downto 0 );
        douta : out STD_LOGIC_VECTOR ( 31 downto 0 ));
end blk_mem_gen_1;


architecture stub of blk_mem_gen_1 is

  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "clka,wea[3:0],addra[13:0],dina[31:0],douta[31:0]";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";

begin
end architecture stub;
