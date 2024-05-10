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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
    port(
    -- inputs
    clk     :   in std_logic; -- native 100MHz FPGA clock
    sw      :   in std_logic_vector(7 downto 0);
    btnC    :   in std_logic; -- button
    btnU    :   in std_logic; -- alu_reset
    
    -- outputs
    led :   out std_logic_vector(15 downto 0);
    -- 7-segment display segments (active-low cathodes)
    seg :   out std_logic_vector(6 downto 0);
    -- 7-segment display active-low enables (anodes)
    an  :   out std_logic_vector(3 downto 0)
);



end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
  component sevenSegDecoder
      Port (
        i_D : in std_logic_vector(3 downto 0);
        o_S : out std_logic_vector(6 downto 0)
      );
    end component sevenSegDecoder;
    
    component Reg_A
      Port (
        i_Cycle : in std_logic_vector(3 downto 0);
        sw : in std_logic_vector(7 downto 0);
        o_A : out std_logic_vector(7 downto 0)
      );
    end component Reg_A;
    
    component Reg_B
      Port (
        i_Cycle : in std_logic_vector(3 downto 0);
        sw : in std_logic_vector(7 downto 0);
        o_B : out std_logic_vector(7 downto 0)
      );
    end component Reg_B;
    
    component TDM4
      generic (
        k_WIDTH : natural := 4
      );
      Port (
        i_clk : in std_logic;
        i_reset : in std_logic;
        i_D3 : in std_logic_vector(k_WIDTH - 1 downto 0);
        i_D2 : in std_logic_vector(k_WIDTH - 1 downto 0);
        i_D1 : in std_logic_vector(k_WIDTH - 1 downto 0);
        i_D0 : in std_logic_vector(k_WIDTH - 1 downto 0);
        o_data : out std_logic_vector(k_WIDTH - 1 downto 0);
        o_sel : out std_logic_vector(3 downto 0)
      );
    end component TDM4;
    
    component ALU
      Port (
        i_A : in std_logic_vector(7 downto 0);
        i_B : in std_logic_vector(7 downto 0);
        i_opcode : in std_logic_vector(2 downto 0);
        o_result : out std_logic_vector(7 downto 0);
        o_flag : out std_logic_vector(2 downto 0)
      );
    end component ALU;
    
    component Controller_FSM
      Port (
        i_adv : in std_logic;
        i_reset : in std_logic;
        o_Cycle : out std_logic_vector(3 downto 0)
      );
    end component Controller_FSM;
    
    component twoscomp_decimal
      Port (
        i_binary : in std_logic_vector(7 downto 0);
        o_negative : out std_logic;
        o_hundreds : out std_logic_vector(3 downto 0);
        o_tens : out std_logic_vector(3 downto 0);
        o_ones : out std_logic_vector(3 downto 0)
      );
    end component;
    
    component clock_divider
      generic ( k_DIV : natural := 2);
      Port (
        i_clk : in std_logic;
        i_reset : in std_logic;
        o_clk : out std_logic
      );
    end component;
  
    -- Signals declarations
    signal sw_regA, sw_regB : std_logic_vector(7 downto 0) := "00000000";
    signal w_Cycle_fsm : std_logic_vector(3 downto 0) := "0000";
    signal w_result_ALU : std_logic_vector(7 downto 0) := "00000000";
    signal w_clk_div : std_logic := '0';
    signal w_negative_twoscomp : std_logic := '0';
    signal w_hundreds_twoscomp, w_tens_twoscomp, w_ones_twoscomp : std_logic_vector(3 downto 0) := "0000";
    signal w_result_sevenSeg : std_logic_vector(6 downto 0) := "0000000";
    signal w_sign : std_logic_vector(3 downto 0) := "0000";
    signal w_output : std_logic_vector (3 downto 0) := "0000";
    signal w_bin : std_logic_vector (7 downto 0) := "00000000";
        
  begin
    -- Instantiations and connections
    process (w_negative_twoscomp) -- turning a wire into a 4 bit
    begin
        if w_negative_twoscomp = '1' then
            w_sign <= "1111"; 
        else
            w_sign <= "1110"; 
        end if;
    end process;
    
    regA_inst : Reg_A
      port map (
        i_Cycle => w_Cycle_fsm,
        sw => sw(7 downto 0),
        o_A => sw_regA
      );
  
    regB_inst : Reg_B
      port map (
        i_Cycle => w_Cycle_fsm,
        sw => sw(7 downto 0),
        o_B => sw_regB
      );
  
    TDM4_inst : TDM4
      generic map (k_WIDTH => 4)
      port map (
        i_clk => w_clk_div,
        i_reset => btnU,
        i_D3 => w_sign,
        i_D2 => w_hundreds_twoscomp,
        i_D1 => w_tens_twoscomp,
        i_D0 => w_ones_twoscomp,
        o_data => w_output,
        o_sel => an  
      );
  
    ALU_inst : ALU
      port map (
        i_A => sw_regA,
        i_B => sw_regB,
        i_opcode => sw(2 downto 0),
        o_result => w_result_ALU,
        o_flag => led(15 downto 13) 
      );
  
    Controller_FSM_inst : Controller_FSM
      port map (
        i_adv => btnC,
        i_reset => btnU,
        o_Cycle => w_Cycle_fsm
      );
  
    twoscomp_inst : twoscomp_decimal
      port map (
        i_binary => w_bin,
        o_negative => w_negative_twoscomp,
        o_hundreds => w_hundreds_twoscomp,
        o_tens => w_tens_twoscomp,
        o_ones => w_ones_twoscomp
      );
  
    clk_div_inst : clock_divider
      generic map ( k_DIV => 2500)
      port map (
        i_clk => clk,
        i_reset => btnU,
        o_clk => w_clk_div
      );
      
    sevenSegDecoder_inst : sevenSegDecoder
          port map (
              i_D => w_output,
              o_S => seg
          );      
    led(3 downto 0) <= w_Cycle_fsm;
    led(12 downto 4) <= (others => '0');
    w_bin <= sw_RegA when w_Cycle_fsm = "0010" else
             sw_RegB when w_Cycle_fsm = "0100" else
             w_result_ALU when w_Cycle_fsm = "1000" else
             "00000000";
end top_basys3_arch;