--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

with A0B.ARMv7M.NVIC_Utilities;
with A0B.Callbacks.Generic_Non_Dispatching;
with A0B.STM32F401.SVD.RCC;

package body A0B.STM32F401.USART is

   procedure Enable_Peripheral_Clock
     (Self : in out Abstract_USART_Driver'Class);

   procedure Setup_Transmit (Self : in out USART_Asynchronous_Device'Class);

   procedure Setup_Receive (Self : in out USART_Asynchronous_Device'Class);

   package On_Interrupt_Callbacks is
     new A0B.Callbacks.Generic_Non_Dispatching
           (USART_Asynchronous_Device, On_Interrupt);

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self          : in out USART_Asynchronous_Device'Class;
      Configuration : Asynchronous_Configuration) is
   begin
      Self.Enable_Peripheral_Clock;

      --  Configure IO pins.

      Self.TX_Pin.Configure_Alternative_Function
        (Line  => Self.TX_Line.all,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.RX_Pin.Configure_Alternative_Function
        (Line  => Self.RX_Line.all,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);

      --  Configure USART in asynchronous (UART) mode.

      declare
         Aux : A0B.STM32F401.SVD.USART.CR1_Register := Self.Peripheral.CR1;

      begin
         Aux.SBK    := False;  --  No break character is transmitted
         Aux.RWU    := False;  --  Receiver in active mode
         Aux.RE     := True;
         --  Receiver is enabled and begins searching for a start bit
         Aux.TE     := True;   --  Transmitter is enabled
         Aux.IDLEIE := False;  --  Interrupt is inhibited
         Aux.RXNEIE := True;   --  XXX Enable only when buffer is set?
         --  An USART interrupt is generated whenever ORE=1 or RXNE=1
         Aux.TCIE   := True;
         --  An USART interrupt is generated whenever TC=1 in the USART_SR
         --  register
         Aux.TXEIE  := False;  --  Interrupt is inhibited
         Aux.PEIE   := False;  --  Interrupt is inhibited
         --  Aux.PS     => <>,     --  Parity check is disabled, meaningless
         Aux.PCE    := False;  --  Parity control disabled
         --  Aux.WAKE   := False;  --  XXX ???
         Aux.M      := False;  --  1 Start bit, 8 Data bits, n Stop bit
         Aux.UE     := False;  --  USART prescaler and outputs disabled
                               --  Disable to be able to configure other
                               --  registers
         Aux.OVER8  := Configuration.Oversampling = Oversampling_8;

         Self.Peripheral.CR1 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.CR2_Register := Self.Peripheral.CR2;

      begin
         --  Aux.ADD   => <>,     --  Not used
         --  Aux.LBDL  => <>,     --  Not used
         --  Aux.LBDIE => <>,     --  Not used
         --  Aux.LBCL  := <>;     --  Not used
         --  Aux.CPHA  := <>;     --  Not used
         --  Aux.CPOL  := <>;     --  Not used
         Aux.CLKEN := False;   --  CK pin disabled
         Aux.STOP  := 2#00#;  --  1 Stop bit
         Aux.LINEN := False;  --  LIN mode disabled

         Self.Peripheral.CR2 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.CR3_Register := Self.Peripheral.CR3;

      begin
         Aux.EIE    := True;
         --  An interrupt is generated whenever DMAR=1 in the USART_CR3
         --  register and FE=1 or ORE=1 or NF=1 in the USART_SR register.
         Aux.IREN   := False;  --  IrDA disabled
         --  Aux.IRLP   => <>,     --  Not used
         Aux.HDSEL  := False;  --  Half duplex mode is not selected
         --  Aux.NACK   => <>,     --  Not used
         Aux.SCEN   := False;  --  Smartcard Mode disabled
         Aux.DMAR   := True;   --  DMA mode is enabled for reception
         Aux.DMAT   := True;   --  DMA mode is enabled for transmission
         Aux.RTSE   := False;  --  RTS hardware flow control disabled
         Aux.CTSE   := False;  --  CTS hardware flow control disabled
         Aux.CTSIE  := False;  --  Interrupt is inhibited
         Aux.ONEBIT := False;  --  Three sample bit method

         Self.Peripheral.CR3 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.BRR_Register := Self.Peripheral.BRR;

      begin
         Aux.DIV_Fraction := Configuration.DIV_Fraction;
         Aux.DIV_Mantissa := Configuration.DIV_Mantissa;

         Self.Peripheral.BRR := Aux;
      end;

      --  Enable USART

      Self.Peripheral.CR1.UE := True;

      --  Clear TC status to avoid interrupt at startup.

      Self.Peripheral.SR.TC := False;

      --  Enable USART interrupts

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Interrupt);

      --  Configure DMA stream for data transmit

      Self.Transmit_Stream.Configure_Memory_To_Peripheral
        (Channel    => Self.Transmit_Channel,
         Peripheral => Self.Peripheral.DR'Address);
      Self.Transmit_Stream.Enable_Transfer_Complete_Interrupt;
      Self.Transmit_Stream.Set_Interrupt_Callback
        (On_Interrupt_Callbacks.Create_Callback (Self));

      --  Configure DMA stream for data receive

      Self.Receive_Stream.Configure_Peripheral_To_Memory
        (Channel    => Self.Receive_Channel,
         Peripheral => Self.Peripheral.DR'Address);
      Self.Receive_Stream.Enable_Transfer_Complete_Interrupt;
      Self.Receive_Stream.Set_Interrupt_Callback
        (On_Interrupt_Callbacks.Create_Callback (Self));
   end Configure;

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Self : in out USART_SPI_Device'Class) is
   begin
      Self.Enable_Peripheral_Clock;

      --  Configure IO pins.

      Self.MOSI_Pin.Configure_Alternative_Function
        (Line  => Self.MOSI_Line.all,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.MISO_Pin.Configure_Alternative_Function
        (Line  => Self.MISO_Line.all,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.SCK_Pin.Configure_Alternative_Function
        (Line  => Self.SCK_Line.all,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);

      Self.NSS_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.NSS_Pin.Set (True);

      --  Configure USART in synchronous mode.

      declare
         Aux : A0B.STM32F401.SVD.USART.CR1_Register := Self.Peripheral.CR1;

      begin
         Aux.SBK    := False;  --  No break character is transmitted
         Aux.RWU    := False;  --  Receiver in active mode
         Aux.RE     := True;
         --  Receiver is enabled and begins searching for a start bit
         Aux.TE     := True;   --  Transmitter is enabled
         Aux.IDLEIE := False;  --  Interrupt is inhibited
         Aux.RXNEIE := True;
         --  An USART interrupt is generated whenever ORE=1 or RXNE=1
         Aux.TCIE   := False;  --  Interrupt is inhibited
         Aux.TXEIE  := False;  --  Interrupt is inhibited
         Aux.PEIE   := False;  --  Interrupt is inhibited
         --  Aux.PS     => <>,     --  Parity check is disabled, meaningless
         Aux.PCE    := False;  --  Parity control disabled
         Aux.WAKE   := False;  --  XXX ???
         Aux.M      := False;  --  1 Start bit, 8 Data bits, n Stop bit
         Aux.UE     := False;  --  USART prescaler and outputs disabled
                               --  Disable to be able to configure other
                               --  registers
         --  Aux.OVER8  => False,  --  oversampling by 16

         Self.Peripheral.CR1 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.CR2_Register := Self.Peripheral.CR2;

      begin
         --  Aux.ADD   => <>,     --  Not used
         --  Aux.LBDL  => <>,     --  Not used
         --  Aux.LBDIE => <>,     --  Not used
         Aux.LBCL  := True;
         --  The clock pulse of the last data bit is output to the CK pin
         Aux.CPHA  := True;
         --  The second clock transition is the first data capture edge
         --  --  The first clock transition is the first data capture edge
         Aux.CPOL  := True;
         --  Steady high value on CK pin outside transmission window.
         --  --  Steady low value on CK pin outside transmission window.
         Aux.CLKEN := True;   --  CK pin enabled
         Aux.STOP  := 2#00#;  --  1 Stop bit
         Aux.LINEN := False;  --  LIN mode disabled

         Self.Peripheral.CR2 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.CR3_Register := Self.Peripheral.CR3;

      begin
         Aux.EIE    := False;  --  Interrupt is inhibited
         Aux.IREN   := False;  --  IrDA disabled
         --  Aux.IRLP   => <>,     --  Not used
         Aux.HDSEL  := False;  --  Half duplex mode is not selected
         --  Aux.NACK   => <>,     --  Not used
         Aux.SCEN   := False;  --  Smartcard Mode disabled
         Aux.DMAR   := False;  --  DMA mode is disabled for reception
         Aux.DMAT   := False;  --  DMA mode is disabled for transmission
         Aux.RTSE   := False;  --  RTS hardware flow control disabled
         Aux.CTSE   := False;  --  CTS hardware flow control disabled
         Aux.CTSIE  := False;  --  Interrupt is inhibited
         --  Aux.ONEBIT := <>  --  No used

         Self.Peripheral.CR3 := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.USART.BRR_Register := Self.Peripheral.BRR;

      begin
         --  500_000 when APB2 @84_000_000 MHz

         Aux.DIV_Fraction := 8;
         Aux.DIV_Mantissa := 10;

         Self.Peripheral.BRR := Aux;
      end;

      --  Enable USART

      Self.Peripheral.CR1.UE := True;

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Interrupt);
   end Configure;

   -----------------------------
   -- Enable_Peripheral_Clock --
   -----------------------------

   procedure Enable_Peripheral_Clock
     (Self : in out Abstract_USART_Driver'Class) is
   begin
      case Self.Controller is
         when 1 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.USART1EN := True;

         when 2 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB1ENR.USART2EN := True;

         when 6 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.USART6EN := True;
      end case;
   end Enable_Peripheral_Clock;

   ------------------
   -- On_Interrupt --
   ------------------

   procedure On_Interrupt (Self : in out USART_Asynchronous_Device'Class) is
      use type A0B.Types.Unsigned_32;

   begin
      if Self.Transmit_Stream.Get_Masked_And_Clear_Transfer_Completed then
         Self.Transmit_Buffers (Self.Transmit_Active).Transferred :=
           Self.Transmit_Buffers (Self.Transmit_Active).Size;
         Self.Transmit_Buffers (Self.Transmit_Active).State := A0B.Success;

         if Self.Transmit_Active /= Self.Transmit_Buffers'Last then
            Self.Transmit_Active := @ + 1;
            Self.Setup_Transmit;

         else
            Self.Transmit_Stream.Disable;

            Self.Transmit_Buffers := null;
         end if;
      end if;

      if Self.Receive_Stream.Get_Masked_And_Clear_Transfer_Completed then
         Self.Receive_Buffers (Self.Receive_Active).Transferred :=
           Self.Receive_Buffers (Self.Receive_Active).Size;
         Self.Receive_Buffers (Self.Receive_Active).State := A0B.Success;

         if Self.Receive_Active /= Self.Receive_Buffers'Last then
            Self.Receive_Active := @ + 1;
            Self.Setup_Receive;

         else
            Self.Receive_Stream.Disable;

            Self.Receive_Buffers := null;

            A0B.Callbacks.Emit_Once (Self.Receive_Finished);
         end if;
      end if;

      if Self.Peripheral.SR.RXNE then
         raise Program_Error;
      end if;

      if Self.Peripheral.SR.TC and Self.Peripheral.CR1.TCIE then
         Self.Peripheral.SR.TC := False;
         --  Clear status

         A0B.Callbacks.Emit_Once (Self.Transmit_Finished);
      end if;
   end On_Interrupt;

   ------------------
   -- On_Interrupt --
   ------------------

   procedure On_Interrupt (Self : in out USART_SPI_Device'Class) is
      Mask  : constant A0B.STM32F401.SVD.USART.CR1_Register :=
        Self.Peripheral.CR1;
      State : constant A0B.STM32F401.SVD.USART.SR_Register  :=
        Self.Peripheral.SR;

   begin
      if State.TXE and Mask.TXEIE then
         Self.Peripheral.CR1.TXEIE := False;
         Self.Peripheral.CR1.TCIE  := True;

         Self.Peripheral.DR.DR :=
           A0B.STM32F401.SVD.USART.DR_DR_Field (Self.Transmit_Buffer.all);

      elsif State.TC and Mask.TCIE then
         Self.Peripheral.CR1.TCIE := False;

         Self.Transmit_Done := True;

         if Self.Receive_Done then
            raise Program_Error;
         end if;
      end if;

      if State.RXNE then
         declare
            Aux : constant A0B.Types.Unsigned_8 :=
              A0B.Types.Unsigned_8 (Self.Peripheral.DR.DR);

         begin
            if Self.Receive_Buffer /= null then
               Self.Receive_Buffer.all := Aux;
            end if;

            Self.Receive_Done := True;
         end;

         if not Self.Transmit_Done then
            raise Program_Error;

         else
            --  Data transmission done

            declare
               Finished : constant A0B.Callbacks.Callback := Self.Finished;

            begin
               Self.Transmit_Buffer := null;
               Self.Receive_Buffer  := null;
               A0B.Callbacks.Unset (Self.Finished);

               A0B.Callbacks.Emit (Finished);
            end;
         end if;
      end if;
   end On_Interrupt;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Self     : in out USART_Asynchronous_Device'Class;
      Buffers  : in out Buffer_Descriptor_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success or Self.Transmit_Buffers /= null then
         Success := False;

         return;
      end if;

      Self.Receive_Buffers  := Buffers'Unrestricted_Access;
      Self.Receive_Active   := Buffers'First;
      Self.Receive_Finished := Finished;

      Self.Setup_Receive;
   end Receive;

   -------------
   -- Receive --
   -------------

   overriding procedure Receive
     (Self            : in out USART_SPI_Device;
      --  Transmit_Placeholder : A0B.Types.Unsigned_8;
      Receive_Buffers : in out A0B.SPI.Buffer_Descriptor_Array;
      On_Finished     : A0B.Callbacks.Callback;
      Success         : in out Boolean) is
   begin
      raise Program_Error;
   end Receive;

   --------------------
   -- Release_Device --
   --------------------

   overriding procedure Release_Device (Self : in out USART_SPI_Device) is
   begin
      Self.NSS_Pin.Set (True);
      --
      --  Self.Transmit_Buffer := null;
      --  Self.Receive_Buffer  := null;
   end Release_Device;

   -------------------
   -- Select_Device --
   -------------------

   overriding procedure Select_Device (Self : in out USART_SPI_Device) is
   begin
      --  Device_Locks.Acquire (Self.Device_Lock, Device, Success);
      --
      --  if not Success then
      --     return;
      --  end if;
      --
      --  Self.Device := Device.Target_Address;
      Self.NSS_Pin.Set (False);
   end Select_Device;

   -------------------
   -- Setup_Receive --
   -------------------

   procedure Setup_Receive (Self : in out USART_Asynchronous_Device'Class) is
   begin
      --  Setup DMA transmission

      Self.Receive_Stream.Set_Memory_Buffer
        (Self.Receive_Buffers (Self.Receive_Active).Address,
         A0B.Types.Unsigned_16
           (Self.Receive_Buffers (Self.Receive_Active).Size));

      Self.Receive_Stream.Clear_Interrupt_Status;
      --  Reset state of the DMA stream

      Self.Receive_Stream.Enable;
   end Setup_Receive;

   --------------------
   -- Setup_Transmit --
   --------------------

   procedure Setup_Transmit (Self : in out USART_Asynchronous_Device'Class) is
   begin
      --  Setup DMA transmission

      Self.Transmit_Stream.Set_Memory_Buffer
        (Self.Transmit_Buffers (Self.Transmit_Active).Address,
         A0B.Types.Unsigned_16
           (Self.Transmit_Buffers (Self.Transmit_Active).Size));

      Self.Transmit_Stream.Clear_Interrupt_Status;
      --  Reset state of the DMA stream

      Self.Transmit_Stream.Enable;
   end Setup_Transmit;

   --------------
   -- Transfer --
   --------------

   overriding procedure Transfer
     (Self              : in out USART_SPI_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Receive_Buffer    : aliased out A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback;
      Success           : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if Self.Transmit_Buffer /= null or Self.Receive_Buffer /= null then
         Success := False;

         return;
      end if;

      Self.Transmit_Buffer := Transmit_Buffer'Unchecked_Access;
      Self.Receive_Buffer  := Receive_Buffer'Unchecked_Access;
      Self.Transmit_Done   := False;
      Self.Receive_Done    := False;
      Self.Finished        := Finished_Callback;

      Self.Peripheral.CR1.TXEIE := True;
   end Transfer;

   --------------
   -- Transmit --
   --------------

   procedure Transmit
     (Self     : in out USART_Asynchronous_Device'Class;
      Buffers  : in out Buffer_Descriptor_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success or Self.Transmit_Buffers /= null then
         Success := False;

         return;
      end if;

      Self.Transmit_Buffers  := Buffers'Unrestricted_Access;
      Self.Transmit_Active   := Buffers'First;
      Self.Transmit_Finished := Finished;

      Self.Setup_Transmit;
   end Transmit;

   --------------
   -- Transmit --
   --------------

   overriding procedure Transmit
     (Self              : in out USART_SPI_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback;
      Success           : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if Self.Transmit_Buffer /= null or Self.Receive_Buffer /= null then
         Success := False;

         return;
      end if;

      Self.Transmit_Buffer := Transmit_Buffer'Unchecked_Access;
      Self.Receive_Buffer  := null;
      Self.Transmit_Done   := False;
      Self.Receive_Done    := False;
      Self.Finished        := Finished_Callback;

      Self.Peripheral.CR1.TXEIE := True;
   end Transmit;

   --------------
   -- Transmit --
   --------------

   overriding procedure Transmit
     (Self              : in out USART_SPI_Device;
      Transmit_Buffers  : in out A0B.SPI.Buffer_Descriptor_Array;
      Finished_Callback : A0B.Callbacks.Callback;
      Success           : in out Boolean) is
   begin
      raise Program_Error;
   end Transmit;

end A0B.STM32F401.USART;
