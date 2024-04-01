import pygame as pg
from enum import Enum


class Agent:
    def __init__(self, _id, _position, _state):
        self.id = _id
        self.position = _position
        self.state = _state
    
    def to_string(self):
        return str(self)

    def to_state(self):
        pass

    def update(self):
        pass

    def decide(self):
        pass

    def __str__(self):
        return "- Base Agent Class -"


class ChefState(Enum):
    WAITING = 1
    COOKING = 2


class Chef(Agent):
    def __init__(self, _id):
        super().__init__(_id, None, ChefState.WAITING)
    
    def to_string(self):
        return str(self)

    def to_state(self):
        pass

    def update(self):
        pass

    def decide(self):
        pass

    def __str__(self):
        return ""


class WaiterState(Enum):
    WAITING = 1
    GETTING = 2
    SENDING = 3


class Waiter(Agent):
    def __init__(self, _id):
        super().__init__(_id, None, WaiterState.WAITING)
    
    def to_string(self):
        pass

    def to_state(self):
        return str(self)

    def update(self):
        pass

    def decide(self):
        pass

    def __str__(self):
        return ""


class ClientState(Enum):
    WAITING = 1
    EATING = 2
    FINISHING = 3


class Client(Agent):
    def __init__(self, _id):
        super().__init__(_id, None, ClientState.WAITING)
    
    def to_string(self):
        return str(self)

    def to_state(self):
        pass

    def update(self):
        pass

    def decide(self):
        pass

    def __str__(self):
        return ""


class Food:
    def __init__(self, _prepTime, _tgCustomerID, _tgWaiterID):
        self.prep_time = _prepTime
        self.tg_customer_id = _tgCustomerID
        self.tg_waiter_id = _tgWaiterID
        self.__t = 0
    
    def is_ready(self):
        return self.__t >= self.prep_time
    
    def step(self):
        self.__t += 1


def main():
    pg.init()

    window = pg.display.set_mode((800, 600))
    running = True

    while running:
        for event in pg.event.get():
            if event.type == pg.QUIT:
                running = False        
        window.fill((26, 52, 52))
        
        pg.display.flip()
    pg.quit()


if __name__ == '__main__':
    main()
