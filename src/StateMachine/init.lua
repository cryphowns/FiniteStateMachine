--[[ 
    DOCS: 
    
    Written by cryphowns | Ryan S.

    This machine data model does not support extended state nor parallel state capabilities.. yet.

    <FORMAT>
    Every Transition array you pass must be a hash table
    every array element in the hash table represents a state, and its elements are events that point to other states

    StateTable = {
        ["State1"] = {
            ["Event1"] = "State2";
        }
    }

    <USAGE>

    local stateModule = PathToStateMachine
	
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
	
	local machine = require("stateModule").new("Idle", myStates)
	
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

]]

--[[ Dependencies ]]

--[[ Module ]]
local machine = {};


--[[ Constructor ]]
function machine.new(initialState, transitionArray)
    --Important checks
    assert(initialState ~= nil, "Cannot construct, initial state has value nil");
    assert(transitionArray ~= nil, "Cannot construct, transitionArray has value nil");
    assert(typeof(initialState) == "string", "initialState must be of type string");
	assert(typeof(transitionArray) == "table", "transitionArray must be of type table");
    if not transitionArray[initialState] then 
        return error("initialState must be an element of transitionArray"); 
    end
	
    --[[ Properties ]]
	local self = setmetatable({}, machine);
	self.transitions = transitionArray;
	self.currentState = initialState;
	self.submachines = {};
	self.currentSubMachine = nil;
	
	--[[ Initialize Events ]]
    self.eventCache = {};
    self.event = Instance.new("BindableEvent");
	self.OnStateChanged = { -- make references 
		event = self.event;
		eventCache = self.eventCache;
	};
	
	--[[ Initialize Event Listener ]]
    function self.OnStateChanged:Connect(callback)
		print(self.event)
		for i,v in pairs(self) do print(i,v) end
        self.eventCache["EventListener"] = self.event.Event:Connect(function(identifier, oldState, newState)
            if identifier == "OnStateChanged" then
                return callback(oldState, newState);
            end
        end)
    end;
	
	return self
end

--[[ Destructor ]]
function machine:destroy()
    for _, connection in pairs(self.eventCache) do
        connection:Disconnect();
    end
    self = nil;
end

--[[ Public Methods ]]
function machine:transition(eventName)
	if self:getCurrentSub() then
		local newState = self:getCurrentSub():transition(eventName);
		if newState then return newState end;
	end

	if self.submachines[eventName] then
        self:setNewSub(eventName);
        local newSub = self:getCurrentSub();
		return newSub:getCurrentState();
	end
	
	return self.transitions[self:getCurrentState()][eventName];
end

function machine:unRegister()
    local currentSub = self:getCurrentSub();
	if currentSub then
        currentSub:unRegister();
        self.currentSubMachine = nil;
	end
end


function machine:switch(eventName, callback)
	local newState = self:transition(eventName);
	assert(newState, "There was an invalid transition from <"..self:getCurrentState().."> to <"..eventName..">");
	if self:getCurrentSub() and self.transitions[newState] then
		self:unRegister();
	end
	
    self.event:Fire("OnStateChanged", self:getCurrentState(), newState);
    self:setNewState(newState);
	if callback then
		callback();
	end
end

function machine:embedSubmachine(eventName, machine)
	self.submachines[eventName] = machine;
end

function machine:setNewState(state)
    self.currentState = state;
end

function  machine:setNewSub(event)
    self.currentSubMachine = self.machines[event];
end

function  machine:getCurrentState()
    return self.currentState;
end

function  machine:getCurrentSub()
    return self.currentSubMachine;
end


--[[Return Logic]]
machine.__index = machine;
machine.__call = function(t, ...)
	t:switch(...);
end
return machine;
