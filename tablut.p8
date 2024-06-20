pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
debug=""
tile_size=10
cursor_x=4
cursor_y=4
selected_x=nil
selected_y=nil
input={}
grid={}
is_defender_turn=false

function clamp(a,b,c)
	if a < b then
		return b
	end
	if a > c then
		return c
	end
	return a
end

function draw_board()
	for x=0,8 do
		for y=0,8 do
			local sprite=1
			if x==0 or x==8 or y==0 or y==8 then
				sprite=3
			elseif x==4 and y==4 then
				sprite=5
			end
			spr(
				sprite,
				x*tile_size-x,
				y*tile_size-y,
				2,
				2
			)
			
			draw_piece(
				grid[x][y],
				x,
				y
			)
		end
	end
	
	local cursor_sprite=32
	if is_defender_turn then
		cursor_sprite=34
	end
	
	--draw cursor
	draw_piece(cursor_sprite,cursor_x,cursor_y)
end

function draw_piece(
	sprite,
	x,
	y
)
	if sprite==nil or x==nil or y==nil then
		return
	end
	spr(
		sprite,
		x*tile_size-x,
		y*tile_size-y,
		2,
		2
	)
end

function update_valid_moves()
	--clear previous moves
	for x=0,8 do
		for y=0,8 do
			if grid[x][y]==13 then
				grid[x][y]=nil
			end
		end
	end
	
	--show valid moves
	if selected_x~=nil and selected_y~=nil then
		local selected_piece=grid[selected_x][selected_y]
		if selected_piece==7 or selected_piece==9 or selected_piece==11 then
			--check to the right
			for x=selected_x+1,8 do
				if grid[x][selected_y]==7 or grid[x][selected_y]==9 or grid[x][selected_y]==11 then
					break
				end
				grid[x][selected_y]=13
			end
			--check to the left
			for x=selected_x-1,0,-1 do
				if grid[x][selected_y]==7 or grid[x][selected_y]==9 or grid[x][selected_y]==11 then
					break
				end
				grid[x][selected_y]=13
			end
			--check to the top
			for y=selected_y-1,0,-1 do
				if grid[selected_x][y]==7 or grid[selected_x][y]==9 or grid[selected_x][y]==11 then
					break
				end
				grid[selected_x][y]=13
			end
			--check to the bottom
			for y=selected_y+1,8 do
				if grid[selected_x][y]==7 or grid[selected_x][y]==9 or grid[selected_x][y]==11 then
					break
				end
				grid[selected_x][y]=13
			end
		end
	end
end

function update_input()
	for i=0,5 do
		input[i].pressed=false
		input[i].released=false
		local prev_down=input[i].down
		if btn(i,0) then
			input[i].down=true
			if not prev_down then
				input[i].pressed=true
			end
		else
			input[i].down=false
			if prev_down then
				input[i].released=true
			end
		end
	end
end

function is_defense(sprite)
	return sprite==7 or sprite==9
end

function can_kill(
	attacker1_x,
	attacker1_y,
	victim_x,
	victim_y,
	attacker2_x,
	attacker2_y
)
	if attacker1_x<0 or attacker1_x>8 or
			 attacker1_y<0 or attacker1_y>8 or
			 victim_x<0 or victim_x>8 or
			 victim_y<0 or victim_y>8 or
			 attacker2_x<0 or attacker2_x>8 or
			 attacker2_y<0 or attacker2_y>8 then
		return false		 
	end
	local attacker1=grid[attacker1_x][attacker1_y]
	local victim=grid[victim_x][victim_y]
	local attacker2=grid[attacker2_x][attacker2_y]
	if attacker1==nil or victim==nil or attacker2==nil then
		return false
	end
	local are_attackers_teamed=is_defense(attacker1)==is_defense(attacker2)
	local is_victim_enemy=is_defense(victim)~=is_defense(attacker1)
 return are_attackers_teamed and is_victim_enemy
end

function kill(x,y)
	local is_king=grid[x][y]==9
	grid[x][y]=nil
	if is_king then
		on_attacker_win()
	end
end

function on_defender_win()
	_init()
end

function on_attacker_win()
	_init()
end

function on_pawn_moved(x,y)
	--check left
	if can_kill(x,y,x-1,y,x-2,y) then
		kill(x-1,y)
	end
	--check right
	if can_kill(x,y,x+1,y,x+2,y) then
		kill(x+1,y)
	end
	--check up
	if can_kill(x,y,x,y-1,x,y-2) then
		kill(x,y-1)
	end
	--check down
	if can_kill(x,y,x,y+1,x,y+2) then
		kill(x,y+1)
	end
	
	is_defender_turn=not is_defender_turn
	
	local pawn=grid[x][y]
	if pawn==9 and (x==0 or x==8 or y==0 or y==8) then --is king
		on_defender_win()
	end
end

function on_selection_changed(
	prev_x,
	prev_y
)
	--piece move logic
	if selected_x~=nil and selected_y~=nil and prev_x~=nil and prev_y~=nil then
		local prev_piece=grid[prev_x][prev_y]
		local cur_piece=grid[selected_x][selected_y]
		if prev_piece==7 or prev_piece==9 or prev_piece==11 then			
			--check if selecting valid move position
			if cur_piece==13 then
				grid[selected_x][selected_y]=prev_piece
				grid[prev_x][prev_y]=nil
				on_pawn_moved(selected_x,selected_y)
				selected_x=nil
				selected_y=nil
			end
		end
	end
end

function can_select(x,y)
	local piece=grid[x][y]
	if piece==nil then
		return false
	end
	if piece==13 then
		return true
	end
	local is_defender=is_defense(piece)
	return (is_defender_turn and is_defender) or (not is_defender_turn and not is_defender)
end

function update_cursor()
	if input[4].pressed then --select
		local prev_selected_x=selected_x
		local prev_selected_y=selected_y
		if cursor_x==selected_x and cursor_y==selected_y then
			selected_x=nil
			selected_y=nil
		elseif can_select(cursor_x,cursor_y) then
			selected_x=cursor_x
			selected_y=cursor_y
		end
		on_selection_changed(
			prev_selected_x,
			prev_selected_y
		)
	end

	if input[0].pressed then
		cursor_x-=1
	end
	if input[1].pressed then
		cursor_x+=1
	end
	if input[2].pressed then
		cursor_y-=1
	end
	if input[3].pressed then
		cursor_y+=1
	end
	cursor_x=clamp(cursor_x,0,8)
	cursor_y=clamp(cursor_y,0,8)
end

function _update()
	update_valid_moves()
	update_input()
	update_cursor()
end

function _init()
	--init input
	cursor_x=4
	cursor_y=4
	selected_x=nil
	selected_y=nil
	for i=0,5 do
		input[i]={}
		input[i].down=false
		input[i].pressed=false
		input[i].released=false
	end
	
	--reset turn
	is_defender_turn=false
	
	--init grid
	for x=0,8 do
		grid[x]={}
		for y=0,8 do
			grid[x][y]=nil
		end
	end
	
	--left attackers
	grid[0][3]=11
	grid[0][4]=11
	grid[0][5]=11
	grid[1][4]=11
	
	--top attackers
	grid[3][0]=11
	grid[4][0]=11
	grid[5][0]=11
	grid[4][1]=11
	
	--right attackers
	grid[8][3]=11
	grid[8][4]=11
	grid[8][5]=11
	grid[7][4]=11
	
	--top attackers
	grid[3][8]=11
	grid[4][8]=11
	grid[5][8]=11
	grid[4][7]=11
	
	--defenders
	grid[2][4]=7
	grid[3][4]=7
	grid[4][4]=9
	grid[5][4]=7
	grid[6][4]=7
	grid[4][2]=7
	grid[4][3]=7
	grid[4][5]=7
	grid[4][6]=7
end

function _draw()
	cls()
	draw_board()
	print(debug)
end
__gfx__
00000000200000000200000020000000020000002000000002000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111110000000000333333000000000044444400000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700010000001000000003000000300000000400000040000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000100000010000000030000003000000004000000400000000000cc00000000000000a900000000000000880000000000000000000000000000000000
00077000010000001000000003000000300000000400000040000000000cccc000000000000cccc0000000000008888000000000000067000000000000000000
007007000100000010000000030000003000000004000000400000000001cc10000000000001cc10000000000002882000000000000015000000000000000000
00000000010000001000000003000000300000000400000040000000000011000000000000001100000000000000220000000000000000000000000000000000
00000000010000001000000003000000300000000400000040000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111110000000000333333000000000044444400000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000000200000020000000020000002000000002000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e80000008e0000007c000000c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8000000008000000c00000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8000000008000000c00000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e80000008e0000007c000000c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
