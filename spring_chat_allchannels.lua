	local springChatAllChannels = torch.class("neuralconvo.springChatAllChannels")
	local stringx = require "pl.stringx"
	local xlua = require "xlua"

	function trim(s)
		if not s then return end
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end

	AllCharacters={}
	characterCounter=0

	local function extractMetaLineFromLog(file)
		local f = assert(io.open(file, 'r'))

		 Lines={}
		LineNr=1
		Sstart, Send=0,0
		
		for line in f:lines() do
		
			Sstart=string.find(line,"<")
			Send =string.find(line,">")
			Lines[LineNr]={}
			
			if  Sstart and Send then 
				Lines[LineNr].boolValidLine=true
				character= trim(string.sub(line,Sstart,Send))
				character2ID = "anyone"
				
				
				if character == "<Nightwatch>" then 
					character= nil
					Sstart, Send= string.find(line,"<Nightwatch>")
					line= string.sub(line,string.len(line))
					
					Sstart, Send= string.find(line,"<"),string.find(line,">")
					if Sstart and Send then
						character= trim(string.sub(line,Sstart,Send))
					end
				end
			
				if character then
					--remove the braces	
					character=string.upper(trim(string.sub(character,2,string.len(character)-1)))
					
					if not AllCharacters[character] then 
						print("New Person:"..character)
						AllCharacters[character]= character 
					end
					
					local searchString=string.sub(line,Send+1,string.len(line)-(Send+1))

					for dramatispersona,_ in pairs(AllCharacters) do
						if string.lower(dramatispersona) ~= string.lower(character) then
							if string.find(searchString,dramatispersona) then
								character2ID= string.upper(dramatispersona)		
							end
						end
						
					end
					
					
						Lines[LineNr]= {		
							characterID=character, 
							character2ID = character2ID,
							text = searchString,
							lineID= LineNr
						}
					
						if Lines[LineNr].character2ID =="anyone" then
						
							if Lines[LineNr-1] and Lines[LineNr-1].characterID	then	
							Lines[LineNr].character2ID = Lines[LineNr-1].characterID
							else
							Lines[LineNr].character2ID=Lines[LineNr].characterID
							end
						end
				end
				 	
			end 
		
			if not Sstart or not Ssend then
				Lines[LineNr].boolValidLine=false	
			end
			
				
		LineNr=LineNr+1
		end 
		f:close() 
		
		return Lines
		
	end

	function springChatAllChannels:__init(dir)
		self.dir = dir
	end


	local TOTAL_LINES = 202581

	local function progress(c)
		if c % 10000 == 0 then
			xlua.progress(c, TOTAL_LINES)
		end
	end

	function springChatAllChannels:load()
		local lines = {}
		local conversations = {}
		local count = 0
		
		print("-- Parsing Chat Dialog data set ...")
		path= self.dir .. "/dataset.txt"
		print(path)
		
		lines =extractMetaLineFromLog(path)
		
		local conversation = {}
		lineAddedCounter=0
		conversationID=0
		
		for index, line in ipairs(lines) do
			if line.boolValidLine == false  and lineAddedCounter > 0 then
				conversation.conversationID=conversationID
				table.insert(conversations, conversation)
				conversation = {}
				conversationID=conversationID+1
				lineAddedCounter= 0
			end
			
			
			table.insert(conversation, line)	
			lineAddedCounter=lineAddedCounter+1
			count = count + 1
			progress(count)
		end
		
		xlua.progress(TOTAL_LINES, TOTAL_LINES)
		
		return conversations
	end
