pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
CURSOR = {
    x = 1,
    y = 1
}
DIFFICULTY = 1
MINES = 10
GRID = {
    x = 8,
    y = 8
}
OFFSET = 4
MINES_LEFT = nil
FIELD = {}
GAME_STATE = 0
TIMER = 0
START_TIME = 0
SERVICE_MSG = ''
SERVICE_MSG_CLR = 7
SERVICE_SPR = nil
MENU_POS = 1

local function find_neighbours(x, y)
    local neighbours = {
        { x + 1, y },
        { x - 1, y },
        { x,     y - 1 },
        { x,     y + 1 },
        { x + 1, y + 1 },
        { x + 1, y - 1 },
        { x - 1, y + 1 },
        { x - 1, y - 1 }
    }
    return neighbours
end

local function clear_zero_neighbours(zero_cell)
    local to_clear = { zero_cell }
    while #to_clear > 0 do
        local item = to_clear[#to_clear]
        to_clear[#to_clear] = nil

        local neighbours = find_neighbours(item.x, item.y)
        for i = 1, #neighbours do
            local nx = neighbours[i][1]
            local ny = neighbours[i][2]
            if nx >= 1 and ny >= 1 and nx <= GRID.x and ny <= GRID.y and FIELD[nx][ny].value ~= -1 then
                -- Only process if not already opened
                if FIELD[nx][ny].status ~= 3 then
                    FIELD[nx][ny].status = 3
                    if FIELD[nx][ny].value == 0 then
                        to_clear[#to_clear + 1] = { x = nx, y = ny }
                    end
                end
            end
        end
    end
end

local function init_field()
    for i = 1, GRID.x do
        FIELD[i] = {}
        for ii = 1, GRID.y do
            FIELD[i][ii] = {
                value = 0,
                status = 1 -- 1: closed, 2: flagged, 3: open
            }
        end
    end

    local mines_placed = 0
    while mines_placed < MINES do
        local x = flr(rnd(GRID.x)) + 1
        local y = flr(rnd(GRID.y)) + 1
        if FIELD[x][y].value == 0 then
            FIELD[x][y].value = -1
            mines_placed = mines_placed + 1

            local neighbours = find_neighbours(x, y)
            for row = 1, #neighbours do
                local nx = neighbours[row][1]
                local ny = neighbours[row][2]
                if nx >= 1 and ny >= 1 and nx <= GRID.x and ny <= GRID.y and FIELD[nx][ny].value ~= -1 then
                    FIELD[nx][ny].value = FIELD[nx][ny].value + 1
                end
            end
        end
    end

    local zero_cell = {}
    for i = 1, #FIELD do
        for ii = 1, #FIELD[i] do
            if FIELD[i][ii].value == 0 then
                zero_cell = { x = i, y = ii }
                FIELD[i][ii].status = 3
                break
            end
        end
        if zero_cell.x then break end
    end
    clear_zero_neighbours(zero_cell)
end

local function move_cursor(xdir, ydir)
    CURSOR.x = CURSOR.x + xdir
    CURSOR.y = CURSOR.y + ydir
    if CURSOR.x < 1 then CURSOR.x = 1 end
    if CURSOR.y < 1 then CURSOR.y = 1 end
    if CURSOR.x > GRID.x then CURSOR.x = GRID.x end
    if CURSOR.y > GRID.y then CURSOR.y = GRID.y end
end

local function flag_cell()
    if FIELD[CURSOR.x][CURSOR.y].status == 1 and MINES_LEFT > 0 then
        FIELD[CURSOR.x][CURSOR.y].status = 2
        MINES_LEFT = MINES_LEFT - 1
    elseif FIELD[CURSOR.x][CURSOR.y].status == 2 then
        FIELD[CURSOR.x][CURSOR.y].status = 1
        MINES_LEFT = MINES_LEFT + 1
    end
end

local function open_cell()
    local success = true
    if FIELD[CURSOR.x][CURSOR.y].status < 3 then
        FIELD[CURSOR.x][CURSOR.y].status = 3

        if FIELD[CURSOR.x][CURSOR.y].value == -1 then
            FIELD[CURSOR.x][CURSOR.y].value = -2
            success = false
        elseif FIELD[CURSOR.x][CURSOR.y].value == 0 then
            clear_zero_neighbours({ x = CURSOR.x, y = CURSOR.y })
        end
    end
    return success
end

local function open_all_cells()
    for i = 1, GRID.x do
        for ii = 1, GRID.y do
            FIELD[i][ii].status = 3
        end
    end
end

local function check_win()
    for i = 1, GRID.x do
        for ii = 1, GRID.y do
            if FIELD[i][ii].status == 2 and FIELD[i][ii].value ~= -1 then
                return false
            end
        end
    end
    return true
end

local function start_game()
    DIFFICULTY = 4 - MENU_POS
    if DIFFICULTY == 2 then
        GRID = {
            x = 12,
            y = 12
        }
        OFFSET = 2
        MINES = 22
    elseif DIFFICULTY == 3 then
        GRID = {
            x = 16,
            y = 15
        }
        OFFSET = 0
        MINES = 37
    end
    MINES_LEFT = MINES

    init_field()
    GAME_STATE = 1
    START_TIME = time()
end

local function update_menu()
    if (btnp(2)) then MENU_POS = MENU_POS - 1 end
    if (btnp(3)) then MENU_POS = MENU_POS + 1 end
    if MENU_POS < 1 then MENU_POS = 3 end
    if MENU_POS > 3 then MENU_POS = 1 end

    if btnp(5) then
        start_game()
    end
end

local function update_game()
    TIMER = ceil(time() - START_TIME)

    local xdir = 0
    local ydir = 0

    if (btnp(4)) then
        sfx(2)
        flag_cell()
    end
    if (btnp(5)) then
        if open_cell() then
            sfx(1)
        else
            GAME_STATE = 2
            SERVICE_MSG = 'GAME OVER'
            SERVICE_MSG_CLR = 8
            SERVICE_SPR = 10
            open_all_cells()
            sfx(3)
            return
        end
    end

    if (btnp(0)) then xdir = -1 end
    if (btnp(1)) then xdir = 1 end
    if (btnp(2)) then ydir = -1 end
    if (btnp(3)) then ydir = 1 end
    move_cursor(xdir, ydir)

    if MINES_LEFT == 0 and check_win() then
        GAME_STATE = 2
        SERVICE_MSG = 'YOU WIN!'
        SERVICE_MSG_CLR = 3
        SERVICE_SPR = 12
        open_all_cells()
        music(4)
    elseif MINES_LEFT == 0 then
        SERVICE_MSG = 'WRONG!'
        SERVICE_MSG_CLR = 8
        SERVICE_SPR = 11
    else
        SERVICE_MSG = ''
        SERVICE_SPR = nil
    end
end

function _update()
    if GAME_STATE == 0 then
        update_menu()
    elseif GAME_STATE == 1 then
        update_game()
    end
end

local function draw_menu()
    print('pico-8 minesweeper', 0, 0)
    print('choose difficulty', 0, 12)
    local options = {'hard', 'medium', 'easy'}
    for i = 1, 3 do
        local point = '[ ]'
        local clr = 7
        if MENU_POS == i then
            point = '[x]'
            clr = 10
        end
        color(clr)
        print(point .. ' ' .. options[i], 0, 24 + (i - 1) * 12)
    end
    color(7)
    print('use ⬆️ and ⬇️ to select', 0, 60)
    print('and press ❎ to start', 0, 72)
end

local function draw_game()
    color(7)
    for i = 1, GRID.x do
        for ii = 1, GRID.y do
            local cell_sprite
            if FIELD[i][ii].status == 1 then
                cell_sprite = 1
            elseif FIELD[i][ii].status == 2 then
                cell_sprite = 2
            elseif FIELD[i][ii].value == -1 then
                cell_sprite = 6
            elseif FIELD[i][ii].value == -2 then
                cell_sprite = 7
            elseif FIELD[i][ii].value >= 1 then
                cell_sprite = 15 + FIELD[i][ii].value
            else
                cell_sprite = 4
            end
            spr(cell_sprite, ((i - 1 + OFFSET) * 8), ((ii + OFFSET - 1) * 8))
        end
    end

    if GAME_STATE == 1 or GAME_STATE == 2 then
        print('MINES: ' .. MINES_LEFT, 0, 123)
        print('TIME: ' .. TIMER, 97, 123)
        -- print(FIELD[CURSOR.x][CURSOR.y].value, 50, 123)
    end
    if GAME_STATE == 1 then
        spr(3, (CURSOR.x - 1) * 8 + OFFSET * 8, (CURSOR.y - 1) * 8 + OFFSET * 8)
    end
    if SERVICE_SPR then
        spr(SERVICE_SPR, 42, 120)
    end
    if SERVICE_MSG then
        color(SERVICE_MSG_CLR)
        print(SERVICE_MSG, 52, 123)
    end
end

function _draw()
    cls(0)
    color(7)
    if GAME_STATE >= 1 then
        draw_game()
    else
        draw_menu()
    end
end


__gfx__
000000007777777677777776bbb00bbb55555555777777766666666588888885000aa000000aa000000000000000000000000000000000000000000000000000
000000007666666576668665b000000b6666666576666665666006658880088500aaaa0000aaaa00000000000000000000000000000000000000000000000000
007007007666666576688665b000000b666666657666666566000065880000850a0aa0a00a0aa0a0000000000000000000000000000000000000000000000000
0007700076666665768886650000000066666665766666656070000580700005aaaaaaaaaccaacca000000000000000000000000000000000000000000000000
0007700076666665766606650000000066666665766666656000000580000005aa0aa0aaaca00aca0077777000088800000000b0000000000000000000000000
007007007666666576660665b000000b666666657666666566000065880000850aa00aa00aa00aa00070707000088800000b0bb0000000000000000000000000
000000007666666576600065b000000b6666666576666665666006658880088500aaaa0000aaaa000077777000088800000bbb00000000000000000000000000
000000006555555565555555bbb00bbb66666665655555555555555555555555000aa000000aa00000077700000000000000b000000000000000000000000000
777777767777777677777776777777767777777677777776777777767777777600000000000aa000000000000000000000000000000000000000000000000000
7666666576666665766666657666666576666665766666657666666576666665000000aa00aaaa00000000000000000000000000000000000000000000000000
7666c6657663336576688865766161657662226576644465766ddd657665556500000aa00a0aa0a0000000000000000000000000000000000000000000000000
7666c665766663657666686576616165766266657664666576666d6576656565000aaa00aaaaaaaa000000000000000000000000000000000000000000000000
7666c665766333657666886576611165766222657664446576666d657665556500aa0000aaa00aaa000000000000000000000000000000000000000000000000
7666c665766366657666686576666165766662657664646576666d65766565650aa000000aa00aa0000000000000000000000000000000000000000000000000
7666c665766333657668886576666165766222657664446576666d65766555650000000000aaaa00000000000000000000000000000000000000000000000000
655555556555555565555555655555556555555565555555655555556555555500000000000aa000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777776777777760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7666c665766666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
766cc6657666c6650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76ccc665766cc6650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
766cc6657666c6650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
766cc6657666c6650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76cccc65766ccc650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555555655555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000000000805608066080570204703057030500304029070210111b06116021120410e0310f0310f0210e0110e0510c0600c0470b0270a0570a03209014080220701207052060710606105050050500405018050
001000001705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000955000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002875027750257501c7501c7501c7501c7501c750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000e0500e050000000000015050150500000000000150501505000000000001105011050000000000010050100500000000000100501005000000000001005010050000001005010050110501105000000
001000000e3500635007350093500a350000001935000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
03 04444444
