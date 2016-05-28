	local springChatAllChannels = torch.class("neuralconvo.springChatAllChannels")
	local stringx = require "pl.stringx"
	local xlua = require "xlua"

	local function parsedLines(file, fields)
		local f = assert(io.open(file, 'r'))
		
		return function()
			local line = f:read("*line")
			
			if line == nil then
				f:close()
				return
			end
			
			local values = stringx.split(line, " ***+*** ")
			local t = {}
			
			for i,field in ipairs(fields) do
				t[field] = values[i]
			end
			
			return t
		end
	end

	function trim6(s)
		if not s then return end
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end

	AllCharacters={}

	local function extractMetaLineFromLog(file)
		local f = assert(io.open(file, 'r'))
		Lines={}
		LineNr=0
		
		for line in fp:lines() do
			character,Send= trim(string.sub(string.find(line,"<"),string.find(line,">")))
			character2ID = "anyone"
			
			if character == "<Nightwatch>" then 
				Sstart, Send= string.find("<Nightwatch>")
				line= string.sub(line,Send)
				character= trim(string.sub(string.find(line,"<"),string.find(line,">")))
			end
			
			if character then
				--remove the braces	
				character=trim(string.sub(character,1,string.len(character)-2))
				
				if not AllCharacters[character] then AllCharacters[character]= character end
				
				searchString=string.sub(line,Send,string.len(line))
				
				for dramatispersona,_ in pairs(AllCharacters) do
					if dramatispersona ~= character then
						if string.find(searchString,dramatispersona) then
							character2ID= dramatispersona		
						end
					end
					
				end
				
				
				Lines[LineNr]= {		character=character, 
					character2ID = character2ID,
					text = searchString,
					lineID= LineNr,
					boolnewConversation= false
				}
				
				if Lines[LineNr-1]	then	
					Lines[LineNr-1].nextLine= LineNr
				end
				
				
			else
				Lines[LineNr]={ boolnewConversation=true
				}
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
		
		for line in extractMetaLineFromLog(self.dir .. "/dataset.txt") do
			lines[line.lineID] = line
		end
		
		conversation = {}
		for line in lines do
			if line.boolnewConversation == true then
				table.insert(conversations, conversation)
				conversation = {}
			end
			table.insert(conversation, line)	
			
			count = count + 1
			progress(count)
		end
		
		xlua.progress(TOTAL_LINES, TOTAL_LINES)
		
		return conversations
	end