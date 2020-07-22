# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import collections


# %%
Card = collections.namedtuple('Card', ['rank', 'suit'])

# 通过特殊方法利用python数据模型的好处
# 1. 作为你的类的用户，他们不必要记住标准操作的各式名称
# 2. 可以更加方便的利用python的标准库，比如random.choice
class FrenchDesk:
    ranks = [str(n) for n in range(2,11)] + list('JQKA')
    suits = 'spades diamonds clubs hearts'.split()
    
    def __init__(self):
        self._cards = [Card(rank, suit) for suit in self.suits
                                        for rank in self.ranks]
    
    def __len__(self):
        return len(self._cards)
    
    def __getitem__(self, position):
        return self._cards[position]


# %%
beer_card = Card('7', 'diamonds')
beer_card


# %%
# 好处1，方便直接使用标准库 len
deck = FrenchDesk()
len(deck)
deck[0]


# %%
# 好处2，方便直接使用标准库，不用重复造轮子
from random import choice
choice(deck)


# %%
# 好处3，支持切片。。
deck[:3]


# %%
# 好处4，支持迭代， 反向迭代
for card in deck:
    print(card)
    break
for card in reversed(deck):
    print(card)
    break


# %%
# 好处5，支持in运算
Card('Q', 'hearts') in deck


# %%
# 好处6，更方便的排序
suit_values = dict(spades=3, hearts=2, diamonds=1, clubs=0)
def spades_high(card):
    rank_value = FrenchDesk.ranks.index(card.rank)
    return rank_value * len(suit_values) + suit_values[card.suit]
# print(spades_high(Card('A', 'spades')))
# print(spades_high(Card('A', 'clubs')))
sorted(deck, key=spades_high )


# %%
from math import hypot
class Vector:
    def __init__(self, x=0, y=0):
        return "Vector {}, {}".format(self.x, self.y)
    
    def __abs__(self):
        return hypot(self.x, self.y)
    
    def __bool__(self):
        return bool(abs(self))

    def __add__(self, other):
        x = self.x + other.x
        y = self.y + other.y
        return Vector(x, y)

    def __mul__(self, scalar):
        return Vector(self.x * scalar, self.y * scalar)


# %%
[1,2,3,1].count(1)


# %%



