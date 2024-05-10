--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
    port (
        --inputs
        i_A      : in std_logic_vector(7 downto 0);
        i_B      : in std_logic_vector(7 downto 0);
        i_opcode : in std_logic_vector(2 downto 0);
        --outputs
        o_result : out std_logic_vector(7 downto 0);
        o_flag   : out std_logic_vector(2 downto 0)
        );
end ALU;

architecture behavioral of ALU is 
  
    signal w_add_result : std_logic_vector(7 downto 0);
    signal w_sub_result : std_logic_vector(7 downto 0);
    signal w_and_result : std_logic_vector(7 downto 0);
    signal w_or_result  : std_logic_vector(7 downto 0);
    signal w_left_shift_result : std_logic_vector(7 downto 0);
    signal w_right_shift_result : std_logic_vector(7 downto 0);
  --  signal w_cout : std_logic;
  --  signal w_zero : std_logic;
  --  signal w_sign : std_logic;

begin

-- Add
    w_add_result <= std_logic_vector(unsigned(i_A) + unsigned(i_B));

-- Sub
    w_sub_result <= std_logic_vector(unsigned(i_A) - unsigned(i_B));
    
-- And
    w_and_result <= i_A and i_B;
    
-- Or 
    w_or_result <= i_A or i_B;
    
-- Left 
    w_left_shift_result <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0))))); -- straight from teams, Thanks!

-- Right
    w_right_shift_result <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));

process(i_opcode)
begin
    case i_opcode is
    when "000" =>
        -- Add
        o_result <= w_add_result;
        
    when "001" =>
        -- Sub
        o_result <= w_sub_result;
        
    when "010" =>
        -- And
        o_result <= w_and_result;

    when "011" =>
        -- Or
        o_result <= w_or_result;
        
    when "100" =>
        -- Left 
        o_result <= w_left_shift_result;
        
    when "101" =>
        -- Right 
        o_result <= w_right_shift_result;
        
    when others =>
        o_result <= (others => '0');
        o_flag <= (others => '0');
    
    end case;
end process;

--o_flag(0) <= w_cout;
--o_flag(1) <= w_zero;
--o_flag(2) <= w_sign;

end behavioral;
