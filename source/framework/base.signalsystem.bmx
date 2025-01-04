SuperStrict
Import Brl.Collections


Type TSignalSystem
	'signalNameID=>signalName
	Field registeredSignalNames:TTreeMap<Ulong, String> = New TTreeMap<Ulong, String>
	Field registeredSignalReceivers:TTreeMap<Ulong, TSignalReceivers> = New TTreeMap<Ulong, TSignalReceivers>
	
	
	Method GetSignalID:ULong(signalName:String)
		Return signalName.ToLower().Hash()
	End Method
	

	'add a signalName and return the generated ID
	Method RegisterSignal:Int(signalName:String)
		Local ID:ULong = signalName.ToLower().Hash()
		'first time a signal is inserted, use their casing style
		If not registeredSignalNames.ContainsKey(ID)
			registeredSignalNames.Add(ID, signalName)
		EndIf
		Return ID
	End Method


	Method RegisterSignalReceiver:Int(signalName:String, callback:Int(signalName:String, data:Object, sender:Object))
		RegisterSignalReceiver(signalName.ToLower().Hash(), callback)
	End Method


	Method RegisterSignalReceiver:Int(signalID:ULong, callback:Int(signalName:String, data:Object, sender:Object))
		Local signalName:String = registeredSignalNames[signalID]
		Local receivers:TSignalReceivers = registeredSignalReceivers[signalID]
		If Not receivers 
			receivers = new TSignalReceivers
			registeredSignalReceivers.Add(signalID, receivers)
		EndIf
		
		Return receivers.Add(callback)
	End Method
	
	
	'returns amount of receivers
	Method EmitSignal:Int(signalName:String, data:Object, sender:Object)
		Return EmitSignal(signalName.ToLower().Hash(), data, sender)
	End Method


	'returns amount of receivers
	Method EmitSignal:Int(signalID:ULong, data:Object, sender:Object)
		Local receivers:TSignalReceivers = registeredSignalReceivers[signalID]
		If Not receivers Then Return 0
		
		Local signalName:String = registeredSignalNames[signalID]
		Return receivers.Run(signalName, data, sender)
	End Method
End Type




Type TSignalReceivers
	Field callbacks:Int(signalName:String, data:Object, sender:Object)[]


	Method Count:Int()
		Return callbacks.length
	End Method
	
	
	Method Contains:Int(callback:Int(signalName:String, data:Object, sender:Object))
		For Local knownCB:Int(signalName:String, data:Object, sender:Object) = EachIn callbacks
			If callback = knownCB Then Return True
		Next
		Return False
	End Method
	
	
	Method Add:Int(callback:Int(signalName:String, data:Object, sender:Object))
		If Not Contains(callback)
			callbacks :+ [callback]
			Return True
		EndIf
		Return False
	End Method
	
	
	Method Run:Int(signalName:String, data:Object, sender:Object)
		For Local cb:Int(signalName:String, data:Object, sender:Object) = EachIn callbacks
			cb(signalName, data, sender)
		Next
		'return true if we did run something
		Return callbacks.length > 0
	End Method
End Type
