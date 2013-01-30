# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import random
try:
    from tkinter import *
except ImportError:
    from Tkinter import *


class Block(object):
    def __init__(self, mmap, x, y, direction=None):
        super(Block, self).__init__()
        self.walls = [True, True, True, True]  # top,right,bottom,left
        self.mmap = mmap
        if mmap:
            mmap.mmap[x][y] = self
        self.x, self.y = x, y
        if direction is not None:
            direction = (direction + 2) % 4
            self.walls[direction] = False

    def __unicode__(self):
        return "%s" % [1 if e else 0 for e in self.walls]

    def __str__(self):
        return unicode(self).encode('utf-8')

    def get_next_block_pos(self, direction):
        x = self.x
        y = self.y
        if direction == 0:  # Top
            y -= 1
        elif direction == 1:  # Right
            x += 1
        if direction == 2:  # Bottom
            y += 1
        if direction == 3:  # Left
            x -= 1
        return x, y

    def get_next_block(self):
        directions = list(range(4))
        random.shuffle(directions)
        for direction in directions:
            if not self.walls[direction]:  # if no wall
                continue
            x, y = self.get_next_block_pos(direction)
            if x >= self.mmap.max_x or x < 0 or y >= self.mmap.max_y or y < 0:
                continue
            if self.mmap.mmap[x][y]:  # if walked
                continue
            self.walls[direction] = False
            return Block(self.mmap, x, y, direction)
        return None


class Map(object):
    def __init__(self):
        super(Map, self).__init__()

    def reset_map(self):
        self.gen_map(self.max_x, self.max_y)

    def gen_map(self, max_x=10, max_y=10):
        self.max_x, self.max_y = max_x, max_y
        self.mmap = [[None for j in range(self.max_y)] for i in range(self.max_x)]
        self.solution = []
        block_stack = [Block(self, 0, 0)]  # a unused block
        while block_stack:
            block = block_stack.pop()
            next_block = block.get_next_block()
            if next_block:
                block_stack.append(block)
                block_stack.append(next_block)
                if next_block.x == self.max_x - 1 and next_block.y == self.max_y - 1:  # is end
                    for o in block_stack:
                        self.solution.append((o.x, o.y))

    def __unicode__(self):
        out = ""
        for y in range(self.max_y):
            for x in range(self.max_x):
                out += "%s" % self.mmap[x][y]
            out += "\n"
        return out

    def __str__(self):
        return unicode(self).encode('utf-8')


class DrawMap(object):
    def __init__(self, mmap, cell_width=10):
        super(DrawMap, self).__init__()
        self.mmap = mmap
        self.cell_width = cell_width

    def get_map_size(self):
        # width, height
        return (self.mmap.max_x + 2) * self.cell_width, (self.mmap.max_y + 2) * self.cell_width

    def create_line(self, x1, y1, x2, y2, **kwarg):
        raise NotImplemented()

    def create_solution_line(self, x1, y1, x2, y2):
        self.create_line(x1, y1, x2, y2)

    def draw_start(self):
        raise NotImplemented()

    def draw_end(self):
        raise NotImplemented()

    def get_cell_center(self, x, y):
        w = self.cell_width
        return (x + 1) * w + w // 2, (y + 1) * w + w // 2

    def draw_solution(self):
        pre = (0, 0)
        for o in self.mmap.solution:
            p1 = self.get_cell_center(*pre)
            p2 = self.get_cell_center(*o)
            self.create_solution_line(p1[0], p1[1], p2[0], p2[1])
            pre = o

    def draw_cell(self, block):
        width = self.cell_width
        x = block.x + 1
        y = block.y + 1
        walls = block.walls
        if walls[0]:
            self.create_line(x * width, y * width, (x + 1) * width + 1, y * width)
        if walls[1]:
            self.create_line((x + 1) * width, y * width, (x + 1) * width, (y + 1) * width + 1)
        if walls[2]:
            self.create_line(x * width, (y + 1) * width, (x + 1) * width + 1, (y + 1) * width)
        if walls[3]:
            self.create_line(x * width, y * width, x * width, (y + 1) * width + 1)

    def draw_map(self):
        for y in range(self.mmap.max_y):
            for x in range(self.mmap.max_x):
                self.draw_cell(self.mmap.mmap[x][y])
        self.draw_start()
        self.draw_end()


class TKDrawMap(DrawMap):
    def __init__(self, mmap):
        super(TKDrawMap, self).__init__(mmap, cell_width=10)
        master = Tk()
        width, height = self.get_map_size()
        self.w = Canvas(master, width=width, height=width)
        self.w.pack()
        self.draw_map()
        mainloop()

    def draw_start(self):
        r = self.cell_width // 3
        x, y = self.get_cell_center(0, 0)
        start = self.w.create_oval(x - r, y - r, x + r, y + r, fill="red")
        self.w.tag_bind(start, '<ButtonPress-1>', lambda e: self.draw_solution())

    def draw_end(self):
        r = self.cell_width // 3
        x, y = self.get_cell_center(self.mmap.max_x - 1, self.mmap.max_y - 1)
        end = self.w.create_oval(x - r, y - r, x + r, y + r, fill="red")
        self.w.tag_bind(end, '<ButtonPress-1>', lambda e: self.reset_map())

    def reset_map(self):
        self.mmap.reset_map()
        self.w.delete('all')
        self.draw_map()

    def create_line(self, x1, y1, x2, y2, **kwargs):
        self.w.create_line(x1, y1, x2, y2, **kwargs)

    def create_solution_line(self, x1, y1, x2, y2):
        self.create_line(x1, y1, x2, y2, fill="red")


def main():
    m = Map()
    m.gen_map(20, 20)
    TKDrawMap(m)

if __name__ == '__main__':
    main()
