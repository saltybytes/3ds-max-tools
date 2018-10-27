(
	global followthem_ro
	
	local mySourceObjects = #()
	
	fn redrawListbox = (
		followthem_ro.objs_lbx.items = for o in mySourceObjects collect o.name
	)
	fn addSelection = (
		mySourceObjects = for o in getCurrentSelection() where isKindOf o geometryclass and classof o != targetObject collect o
		redrawListbox()
	)
	fn removeSelection = (
		local sel = followthem_ro.objs_lbx.selection as array
		for i=sel.count to 1 by -1 do ( deleteItem mySourceObjects i )
		redrawListbox()
	)
	fn selectObj index = (
		if isValidNode mySourceObjects[index] then ( select mySourceObjects[index] )
	)
	fn process = with redraw off (
		-- Just one more check
		mySourceObjects = for o in mySourceObjects where isValidNode o collect o
		
		if mySourceObjects.count > 0 then (
			-- Create trackers
			progressStart "Creating trackers"
			local Trackers = #()
			totalObjects = mySourceObjects.count
			for i=1 to mySourceObjects.count do (
				getProgressCancel()
				append Trackers (Point isSelected:off wirecolor:Black name:(uniquename "Tracker") centermarker:on axistripod:off cross:off Box:off constantscreensize:off drawontop:off transform:mySourceObjects[i].transform)
				progressUpdate (i/totalObjects*100.0)
			)
			progressEnd()
			
			
			-- Track motion
			progressStart "Tracking started"
			local animationStart = followthem_ro.start_spn.value
			local animationEnd = followthem_ro.end_spn.value
			for t=animationStart to animationEnd do at time t with animate on (
				getProgressCancel()
				for i=1 to trackers.count do ( trackers[i].transform = mySourceObjects[i].transform )
				progressUpdate (t/animationEnd*100.0)
			)
			progressEnd()
			
			
			-- Attach objects
			progressStart "Attaching objects"
			local myMesh = Editable_mesh name:("FollowThem")
			local lastMax = 0
			local VerSel = #()
			for i=1 to Trackers.count do (
				append VerSel (for i=1 to mySourceObjects[i].mesh.numverts collect (i+lastMax))
				lastMax += VerSel[i].count
				
				attach myMesh mySourceObjects[i]
				progressUpdate (i/totalObjects*100.0)
			)
			progressEnd()
			
			-- Skin mesh
			local storeTaskMode = getCommandPanelTaskMode()
			setCommandPanelTaskMode #modify
			addModifier myMesh (Skin())  ui:on
			select myMesh
			for i=1 to Trackers.count do (
				skinOps.addBone myMesh.modifiers[#Skin] Trackers[i] 0
				skinOps.SelectBone myMesh.modifiers[#Skin] i
				skinOps.SelectVertices myMesh.modifiers[#Skin] VerSel[i]
				skinOps.setWeight myMesh.modifiers[#Skin] 1
			)
			setCommandPanelTaskMode storeTaskMode
			mySourceObjects = #()
			
			redrawListbox()
			MessageBox "Finished!"
		)
		else (
			redrawListbox()
			MessageBox "The list was empty. Please add a few objects and try again."
		)
	)
	
	try(destroyDialog followthem_ro)catch()
	rollout followthem_ro "FollowThem" width:256 height:528 (
		multiListBox objs_lbx "" pos:[8,8] width:240 height:33
		button add_btn "Add selection" pos:[8,448] width:120 height:16 toolTip:"Add selected objects"
		button remove_btn "Remove objects" pos:[128,448] width:120 height:16 toolTip:"Remove selected object"
		label range_lbl "Range.............................." pos:[8,472] width:128 height:16
		spinner start_spn "" pos:[136,472] width:56 height:16 range:[-9999,9999,0] type:#integer
		spinner end_spn "" pos:[192,472] width:56 height:16 range:[-9999,9999,100] type:#integer
		button go_btn "GO!" pos:[8,496] width:240 height:24 toolTip:"Start calculations. Cant be undone"
		
		
		
		on add_btn pressed do ( addSelection() )
		on remove_btn pressed do ( removeSelection() )
		on objs_lbx doubleClicked index do ( selectObj index )
		on go_btn pressed do ( process() )
	)
	createDialog followthem_ro
)