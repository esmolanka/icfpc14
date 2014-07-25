module Assembler where

newtype Address = Address Int
                deriving (Show, Eq, Ord)

data Commands = LDC Int             -- load constant
              | LD Int Int          -- load from environment, frame and i'th element of frame
              | ADD                 -- integer addition
              | SUB                 -- integer subtraction
              | MUL                 -- integer multiplication
              | DIV                 -- integer division
              | CEQ                 -- compare equal
              | CGT                 -- compare greater than
              | CGTE                -- compare greater than or equal
              | ATOM                -- test if value is an integer
              | CONS                -- allocate a CONS cell
              | CAR                 -- extract first element from CONS cell
              | CDR                 -- extract second element from CONS cell
              | SEL Address Address -- conditional branch
              | JOIN                -- return from branch
              | LDF Address         -- load function
              | AP Int              -- call function, number of arguments to copy
              | RTN                 -- return from function call
              | DUM Int             -- create empty environment frame, size of frame to allocate
              | RAP Int             -- recursive environment call function, number of arguments to copy
              | STOP                -- terminate co-processor execution
              deriving (Show, Eq, Ord)

-- TODO-codes
-- TSEL - tail-call conditional branch
-- Synopsis: pop an integer off the data stack;
--           test if it is non-zero;
--           jump to the true address or to the false address
-- Syntax:  TSEL $t $f
-- Example: TSEL 335 346  ; absolute instruction addresses
--
-- TAP - tail-call function
-- Synopsis: pop a pointer to a CLOSURE cell off the data stack;
--           allocate an environment frame of size $n;
--           set the frame's parent to be the environment frame pointer
--             from the CLOSURE cell;
--           fill the frame's body with $n values from the data stack;
--           set the current environment frame pointer to the new frame;
--           jump to the code address from the CLOSURE cell;
-- Syntax:  TAP $n
-- Example: TAP 3      ; number of arguments to copy
-- Notes:
--   This instruction is the same as AP but it does not push a return address
--
--   The latest hardware revision optimizes the case where the environment
--   frame has not been captured by LDF and the number of args $n in the
--   call fit within the current frame. In this case it will overwrite the
--   frame rather than allocating a fresh one.
--
-- TRAP - recursive environment tail-call function
-- Synopsis: pop a pointer to a CLOSURE cell off the data stack;
--           the current environment frame pointer must point to an empty
--             frame of size $n;
--           fill the empty frame's body with $n values from the data stack;
--           set the current environment frame pointer to the environment
--             frame pointer from the CLOSURE cell;
--           jump to the code address from the CLOSURE cell;
-- Syntax:  TRAP $n
-- Example: TRAP 3      ; number of arguments to copy
-- Notes:
--   This instruction is the same as RAP but it does not push a return address
--
-- Pascal extensions
-- ST - store to environment
-- Synopsis: pop a value from the data stack and store to the environment
-- Syntax:  ST $n $i
-- Example: ST 0 1
--
-- Debug extensions
--
-- DBUG - printf debugging
-- Synopsis: If tracing is enabled, suspend execution and raise a trace
--           interrupt on the main processor. The main processor will read
--           the value and resume co-processor execution. On resumption
--           the value will be popped from the data stack. If tracing is not
--           enabled the value is popped from the data stack and discarded.
-- Syntax:  DBUG
-- Notes:
--   This is the formal effect on the state of the machine. It does
--   also raise an interrupt but this has no effect on the machine state.
--
-- BRK - breakpoint debugging
-- Synopsis: If breakpoint debugging is enabled, suspend execution and raise
--           a breakpoint interrupt on the main processor. The main processor
--           may inspect the state of the co-processor and can resume
--           execution. If breakpoint debugging is not enabled it has no
--           effect.
-- Syntax:  BRK

