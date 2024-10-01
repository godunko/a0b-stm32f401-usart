--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F401.SVD.RCC;

package body A0B.STM32F401.USART is

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Self : in out USART_SPI_Device'Class) is
   begin
      --  Enable peripheral's clock.

      case Self.Controller is
         when 1 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.USART1EN := True;

         when 2 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB1ENR.USART2EN := True;

         when 6 =>
            A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.USART6EN := True;
      end case;

      --  Configure IO pins.

      Self.MOSI_Pin.Configure_Alternative_Function
        (Line  => Self.MOSI_Line,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.MISO_Pin.Configure_Alternative_Function
        (Line  => Self.MISO_Line,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      Self.SCK_Pin.Configure_Alternative_Function
        (Line  => Self.SCK_Line,
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

end A0B.STM32F401.USART;
