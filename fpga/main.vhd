----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:03:02 12/15/2012 
-- Design Name: 
-- Module Name:    main - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library machxo2;
use machxo2.all;

entity main is
	port (
		BTN: in std_logic;
		PX_CLK: out std_logic;
		DE: out std_logic;	
		PWM: out std_logic;
		RED: out std_logic_vector(0 downto 0);
		GREEN: out std_logic_vector(0 downto 0);
		BLUE: out std_logic_vector(0 downto 0)		
	);
end main;



architecture Behavioral of main is
    constant TDEH: integer := 800;
    constant TDEL: integer := 256;
    constant TDEB: integer := 28;  
	constant TDE: integer := 600;

	signal Hcount: std_logic_vector(10 downto 0) := (others => '0');
    signal Vcount: std_logic_vector(9 downto 0) := (others => '0');	
	
	signal PixelClock: std_logic;
	signal LockedClk: std_logic;
	signal CLKIN_BUF: std_logic;
	signal Clock0: std_logic;
	
	signal Prescaler: std_logic_vector(23 downto 0);
	signal Tick: std_logic := '0';
	signal PWM_Output: std_logic := '0';
	
	constant squareWidth: integer := 45;
	constant squareHeight: integer := 45;
	signal squareLeft: std_logic_vector(10 downto 0);
	signal squareTop: std_logic_vector(10 downto 0);
	signal moveRight: std_logic := '1';
	signal moveDown: std_logic := '1';
	
	type imageData_t is array(0 to 45) of std_logic_vector(45 downto 0);
	constant imageData : imageData_t := (	"0000000000000000001111111111000000000000000000",
														"0000000000000111111111111111111110000000000000",
														"0000000000001111111111111111111111000000000000",
														"0000000000011111111111111111111111100000000000",
														"0000000001111111111111111111111111111000000000",
														"0000000011111111111111111111111111111100000000",
														"0000001111111111111111111111111111111111000000",
														"0000011111111111111111111111111111111111100000",
														"0000111111111111111111111111111111111111110000",
														"0000111111111111111111111111111111111111110000",
														"0001111111111111111111111111111111111111111000",
														"0001111111111111111111111111111111111111111000",
														"0011111111111111111111111111111111111111111100",
														"0111111111111100001111111111000011111111111110",
														"0111111111111000000111111110000001111111111110",
														"0111111111111000000111111110000001111111111110",
														"0111111111111000000111111110000001111111111110",
														"0111111111111000000111111110000001111111111110",
														"1111111111111100001111111111000011111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111111111111111111111111111111111111111",
														"1111111111110000000000000000000000111111111111",
														"0111111111110000000000000000000000111111111110",
														"0111111111110000000000000000000000111111111110",
														"0111111111110000000000000000000000111111111110",
														"0111111111111000000000000000000001111111111110",
														"0111111111111000000000000000000001111111111110",
														"0011111111111100000000000000000011111111111100",
														"0001111111111100000000000000000011111111111000",
														"0001111111111111000000000000001111111111111000",
														"0000111111111111110000000000111111111111110000",
														"0000011111111111111000000001111111111111100000",
														"0000011111111111111111111111111111111111100000",
														"0000000111111111111111111111111111111110000000",
														"0000000011111111111111111111111111111100000000",
														"0000000001111111111111111111111111111000000000",
														"0000000000011111111111111111111111100000000000",
														"0000000000001111111111111111111111000000000000",
														"0000000000000011111111111111111100000000000000",
														"0000000000000000001111111111000000000000000000");
	
	signal imageDataX: integer := 0;
	signal imageDataY: integer := 0;
	signal imageDataCurrent: std_logic_vector(45 downto 0);
	
	COMPONENT OSCH
		GENERIC (NOM_FREQ: string := "38.00");
		PORT (STDBY:IN std_logic;
			OSC:OUT std_logic;
			SEDSTDBY:OUT std_logic);
	END COMPONENT;
	attribute NOM_FREQ : string;
	attribute NOM_FREQ of Clock : label is "38.00";

	
begin

	PWM_Control: process(BTN)
	begin
		if falling_edge(BTN) then
			PWM_Output <= not PWM_Output;
		end if;		
	end process;

	Clock: OSCH
		GENERIC MAP( NOM_FREQ => "38.00" )
		PORT MAP (STDBY=> '0', OSC => PixelClock);

	PixelCounter: process(PixelClock)
	begin
		if rising_edge(PixelClock) then
			if (Hcount < (TDEH+TDEL)) then
				Hcount <= Hcount + 1;
			else
				if (Vcount < (TDE+TDEB)) then
					Vcount <= Vcount + 1;
				else
					Vcount <= (others => '0');
				end if;
				Hcount <= (others => '0');
			end if;
		end if;
	end process;
		
	SecondGenerator: process(PixelClock)
	begin
		if rising_edge(PixelClock) then
			if (Prescaler <= "11110100001001000") then
				Prescaler <= Prescaler + 1;
			else
				Prescaler <= (others => '0');
				Tick <= not Tick;
			end if;
		end if;
	end process;
	
	Changer: process(Tick)
	begin
		if rising_edge(Tick) then
			if (moveRight = '1') then
				if (squareLeft < (800-squareWidth)) then
					squareLeft <= squareLeft + 1;
				else
					moveRight <= '0';
				end if;
			else
				if (squareLeft > 0) then
					squareLeft <= squareLeft - 1;
				else
					moveRight <= '1';
				end if;			
			end if;
			
			if (moveDown = '1') then
				if (squareTop < (600-squareHeight)) then
					squareTop <= squareTop + 1;
				else
					moveDown <= '0';
				end if;	
			else
				if (squareTop > 0) then
					squareTop <= squareTop - 1;
				else
					moveDown <= '1';
				end if;				
			end if;
		end if;
	end process;	
	

PX_CLK <= PixelClock;	

DE <= '1' when ((Hcount < TDEH) and (Vcount < TDE)) else '0';

PWM <= PWM_Output;


RED <= "1" when (Hcount >= squareLeft) and (Hcount <= (squareLeft+squareWidth)) and (Vcount >= squareTop) and (Vcount <= (squareTop+squareHeight)) and  (imageDataCurrent(imageDataX) = '1') else -- (conv_std_logic_vector(imageDataX, 5)(0) = '1')
		 "1" when (Hcount >= 0) and (Hcount < 266) else
		 "0";
GREEN <= "1" when (Hcount >= squareLeft) and (Hcount <= (squareLeft+squareWidth)) and (Vcount >= squareTop) and (Vcount <= (squareTop+squareHeight)) and (imageDataCurrent(imageDataX) = '1') else
		   "1" when (Hcount >= 266) and (Hcount < 532) else
		   "0";		 
BLUE <= "1" when (Hcount >= squareLeft) and (Hcount <= (squareLeft+squareWidth)) and (Vcount >= squareTop) and (Vcount <= (squareTop+squareHeight)) and (imageDataCurrent(imageDataX) = '1') else
		  "1" when (Hcount >= 532) and (Hcount < 800) else
		  "0";		 
		 

imageDataCurrent <= imageData(imageDataY);

imageDataX <= conv_integer(unsigned((Hcount-squareLeft)));
imageDataY <= conv_integer(unsigned((Vcount-squareTop)));
	


end Behavioral;

