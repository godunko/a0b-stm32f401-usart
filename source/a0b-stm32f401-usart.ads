--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART drivers

pragma Restrictions (No_Elaboration_Code);

with System;

with A0B.Callbacks;
with A0B.SPI;
with A0B.STM32F401.DMA;
with A0B.STM32F401.GPIO;
with A0B.STM32F401.SVD.USART;
with A0B.Types;

package A0B.STM32F401.USART
  with Preelaborate
is

   type Buffer_Descriptor is record
      Address     : System.Address;
      Size        : A0B.Types.Unsigned_32;
      Transferred : A0B.Types.Unsigned_32;
      State       : A0B.Operation_Status;
   end record;
   --  Descriptor of the transmit/receive buffer.
   --
   --  @component Address       Address of the first byte of the buffer memory
   --  @component Size          Size of the buffer in bytes
   --  @component Transferred   Number of byte transferred by the operation
   --  @component State         State of the operation

   type Buffer_Descriptor_Array is
     array (A0B.Types.Unsigned_32 range <>) of Buffer_Descriptor;

   type Controller_Number is range 1 .. 6
     with Static_Predicate => Controller_Number in 1 | 2 | 6;

   type Oversampling_Mode is (Oversampling_8, Oversampling_16);

   type Asynchronous_Configuration is record
      Oversampling : Oversampling_Mode;
      DIV_Fraction : A0B.STM32F401.SVD.USART.BRR_DIV_Fraction_Field;
      DIV_Mantissa : A0B.STM32F401.SVD.USART.BRR_DIV_Mantissa_Field;
   end record;

   type USART_Asynchronous_Device
     (Peripheral       : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller       : Controller_Number;
      Interrupt        : A0B.STM32F401.Interrupt_Number;
      Transmit_Stream  : not null access A0B.STM32F401.DMA.DMA_Stream'Class;
      Transmit_Channel : A0B.STM32F401.DMA.Channel_Number;
      Receive_Stream   : not null access A0B.STM32F401.DMA.DMA_Stream'Class;
      Receive_Channel  : A0B.STM32F401.DMA.Channel_Number;
      TX_Pin           : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      TX_Line          : not null access constant A0B.STM32F401.Function_Line_Descriptor;
      RX_Pin           : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      RX_Line          : not null access constant A0B.STM32F401.Function_Line_Descriptor)
   is tagged limited private
     with Preelaborable_Initialization;

   procedure Configure
     (Self          : in out USART_Asynchronous_Device'Class;
      Configuration : Asynchronous_Configuration);

   procedure Transmit
     (Self     : in out USART_Asynchronous_Device'Class;
      Buffers  : in out Buffer_Descriptor_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   procedure Receive
     (Self     : in out USART_Asynchronous_Device'Class;
      Buffers  : in out Buffer_Descriptor_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   type USART_SPI_Device
     (Peripheral : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller : Controller_Number;
      Interrupt  : A0B.STM32F401.Interrupt_Number;
      MOSI_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MOSI_Line  :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      MISO_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MISO_Line  :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      SCK_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      SCK_Line   :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      NSS_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class)
   is limited new A0B.SPI.SPI_Slave_Device with private
     with Preelaborable_Initialization;

   procedure Configure (Self : in out USART_SPI_Device'Class);

private

   --  package Device_Locks is
   --
   --     type Lock is limited private with Preelaborable_Initialization;
   --
   --     procedure Acquire
   --       (Self    : in out Lock;
   --        Device  : not null I2C_Device_Driver_Access;
   --        Success : in out Boolean);
   --
   --     procedure Release
   --       (Self    : in out Lock;
   --        Device  : not null I2C_Device_Driver_Access;
   --        Success : in out Boolean);
   --
   --     function Device (Self : Lock) return I2C_Device_Driver_Access;
   --
   --  private
   --
   --     type Lock is limited record
   --        Device : I2C_Device_Driver_Access;
   --     end record;
   --
   --     function Device (Self : Lock) return I2C_Device_Driver_Access is
   --       (Self.Device);
   --
   --  end Device_Locks;

   ---------------------------
   -- Abstract_USART_Driver --
   ---------------------------

   type Abstract_USART_Driver
     (Peripheral : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller : Controller_Number) is abstract tagged limited null record;

   type USART_Asynchronous_Device
     (Peripheral       :
        not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller       : Controller_Number;
      Interrupt        : A0B.STM32F401.Interrupt_Number;
      Transmit_Stream  : not null access A0B.STM32F401.DMA.DMA_Stream'Class;
      Transmit_Channel : A0B.STM32F401.DMA.Channel_Number;
      Receive_Stream   : not null access A0B.STM32F401.DMA.DMA_Stream'Class;
      Receive_Channel  : A0B.STM32F401.DMA.Channel_Number;
      TX_Pin           : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      TX_Line          : not null access constant A0B.STM32F401.Function_Line_Descriptor;
      RX_Pin           : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      RX_Line          : not null access constant A0B.STM32F401.Function_Line_Descriptor)
   is limited new Abstract_USART_Driver (Peripheral, Controller) with record
      Transmit_Buffers  : access Buffer_Descriptor_Array;
      Transmit_Active   : A0B.Types.Unsigned_32;
      Transmit_Finished : A0B.Callbacks.Callback;
      Receive_Buffers   : access Buffer_Descriptor_Array;
      Receive_Active    : A0B.Types.Unsigned_32;
      Receive_Finished  : A0B.Callbacks.Callback;
   end record;

   procedure On_Interrupt (Self : in out USART_Asynchronous_Device'Class);

   ----------------------
   -- USART_SPI_Device --
   ----------------------

   type USART_SPI_Device
     (Peripheral : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller : Controller_Number;
      Interrupt  : A0B.STM32F401.Interrupt_Number;
      MOSI_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MOSI_Line  :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      MISO_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MISO_Line  :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      SCK_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      SCK_Line   :
        not null access constant A0B.STM32F401.Function_Line_Descriptor;
      NSS_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class) is
     limited new Abstract_USART_Driver (Peripheral, Controller)
       and A0B.SPI.SPI_Slave_Device with record
      --  Device_Lock : Device_Locks.Lock;
      Transmit_Buffer : access constant A0B.Types.Unsigned_8;
      Transmit_Done   : Boolean;
      Receive_Buffer  : access A0B.Types.Unsigned_8;
      Receive_Done    : Boolean;
      Finished        : A0B.Callbacks.Callback;
   end record;

   overriding procedure Transfer
     (Self              : in out USART_SPI_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Receive_Buffer    : aliased out A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback;
      Success           : in out Boolean);

   overriding procedure Transmit
     (Self              : in out USART_SPI_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback;
      Success           : in out Boolean);

   overriding procedure Select_Device (Self : in out USART_SPI_Device);

   overriding procedure Release_Device (Self : in out USART_SPI_Device);

   procedure On_Interrupt (Self : in out USART_SPI_Device'Class);

end A0B.STM32F401.USART;
