library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boot_module_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 14
	);
	port (
      -- Users to add ports here
      bram_addr_o : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      bram_data_i : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      bram_data_o : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      bram_wea_o  : out std_logic_vector(3 downto 0);
      -- User ports ends

		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end boot_module_v1_0_S00_AXI;

architecture arch_imp of boot_module_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal bram_rdata	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal bram_wdata	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

    constant BRAM_DELAY    : natural := 2;
    signal bram_addr_ready : std_logic;
    signal bram_data_valid : std_logic;
    signal bram_addr       : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;

	-- -- Implement axi_awready generation
	-- -- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- -- de-asserted when reset is low.

	-- process (S_AXI_ACLK)
	-- begin
	--   if rising_edge(S_AXI_ACLK) then 
	--     if S_AXI_ARESETN = '0' then
	--       axi_awready <= '0';
	--       aw_en <= '1';
	--     else
	--       if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	--         -- slave is ready to accept write address when
	--         -- there is a valid write address and write data
	--         -- on the write address and data bus. This design 
	--         -- expects no outstanding transactions. 
	--            axi_awready <= '1';
	--            aw_en <= '0';
	--         elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	--            aw_en <= '1';
	--            axi_awready <= '0';
	--       else
	--         axi_awready <= '0';
	--       end if;
	--     end if;
	--   end if;
	-- end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 


	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
          bram_addr <= (others => '1');
          bram_addr_ready <= '0';
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
            bram_addr_ready <= '1';
	        -- Read Address latching
	        axi_araddr  <= S_AXI_ARADDR;
            bram_addr <= S_AXI_ARADDR;
          elsif axi_awready = '0' and S_AXI_AWVALID = '1' then
            axi_awready <= '1';
            bram_addr_ready <= '1';
            bram_addr <= S_AXI_AWADDR;
            axi_awaddr <= S_AXI_AWADDR;
	      else
	        axi_arready <= '0';
	        axi_awready <= '0';
	        bram_addr_ready <= '0';
	      end if;
	    end if;
	  end if;
	end process;


    bram_addr_o <= bram_addr;
    bram_data_o <= (others => '0');
    bram_wea_o <= (others => '0');

	process (S_AXI_ACLK)
      variable delay_signal : natural := 0;
	begin
      if rising_edge(S_AXI_ACLK) then
        if S_AXI_ARESETN = '0' then
          delay_signal := 0;
          bram_rdata <= (others => '0');
          bram_data_valid <= '0';
        else
          bram_data_valid <= '0';
          if delay_signal > 0 then
            delay_signal := delay_signal - 1;
            if delay_signal = 0 then
              bram_rdata <= bram_data_i;
              bram_data_valid <= '1';
            end if;
          elsif bram_addr_ready = '1' then
            delay_signal := BRAM_DELAY;
          end if;
        end if;
      end if;
    end process; 


	-- Output register or memory read data
	process (S_AXI_ACLK) is
	begin
	  if rising_edge(S_AXI_ACLK) then
        if S_AXI_ARESETN = '0' then
          axi_rdata  <= (others => '0');
          axi_rvalid <= '0';
          axi_rresp <= "00";
        else
          if bram_data_valid = '1' then
            axi_rdata <= bram_rdata;     -- register read data
            axi_rvalid <= '1';
          elsif axi_rvalid = '1' and S_AXI_RREADY = '1' then
            axi_rvalid <= '0';
          end if;
        end if;
      end if;
	end process;


	-- Add user logic here

	-- User logic ends

end arch_imp;
