--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART drivers

pragma Restrictions (No_Elaboration_Code);

private with A0B.Callbacks;
with A0B.SPI;
with A0B.STM32F401.GPIO;
with A0B.STM32F401.SVD.USART;
private with A0B.Types;

package A0B.STM32F401.USART
  with Preelaborate
is

   type Controller_Number is range 1 .. 6
     with Static_Predicate => Controller_Number in 1 | 2 | 6;

   type USART_SPI_Device
     (Peripheral : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller : Controller_Number;
      Interrupt  : A0B.STM32F401.Interrupt_Number;
      MOSI_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MOSI_Line  : A0B.STM32F401.Function_Line;
      MISO_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MISO_Line  : A0B.STM32F401.Function_Line;
      SCK_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      SCK_Line   : A0B.STM32F401.Function_Line;
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

   type USART_SPI_Device
     (Peripheral : not null access A0B.STM32F401.SVD.USART.USART_Peripheral;
      Controller : Controller_Number;
      Interrupt  : A0B.STM32F401.Interrupt_Number;
      MOSI_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MOSI_Line  : A0B.STM32F401.Function_Line;
      MISO_Pin   : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      MISO_Line  : A0B.STM32F401.Function_Line;
      SCK_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
      SCK_Line   : A0B.STM32F401.Function_Line;
      NSS_Pin    : not null access A0B.STM32F401.GPIO.GPIO_Line'Class) is
   limited new A0B.SPI.SPI_Slave_Device with record
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
