# Finite State Machine
Written by cryphowns | <glocation87@gmail.com>

This machine data model does not support extended state nor parallel state capabilities.. yet.

## Format
Every StateTable you pass must be a hash table.
    Every array element in the hash table represents a state, and its elements are events that point to other states.

    StateTable = {
        ["State1"] = {
            ["Event1"] = "State2";
        }
    }


## Usage

	
	local myStates = {
		["Walking"] = { 
			["Stop"] = "Idle";
			["Jump"] = "Falling";
		}
		
		["Idle"] = {
			["Walk"] = "Walking;
			["Jump"] = "Falling";
		}
		
		["Falling"] = {
			["Landed"] = "Idle";
		}
	}
	
	local machine = require("StateModule").new("Idle", myStates)
	
	machine:switch("Walk")
	print(machine:getCurrentState()) --> "Walking"
	
	machine:switch("Jump")
	print(machine:getCurrentState()) --> "Falling"
	
	machine:switch("Landed")
	print(machine:getCurrentState()) --> "Idle"
	
	machine.OnStateChanged:Connect(function(oldState, newState)
		print("From :"..oldState.." To: "..newState)
	end)

    Output:
    From: Idle To: Walking
    From: Walking To: Falling
    From: Falling: To: Idle
