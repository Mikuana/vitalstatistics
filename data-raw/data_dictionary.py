import json
from birthcount import __dictionary_path__


class DataDictionary(object):
    with open(__dictionary_path__) as f:
        raw = json.load(f)


class Columns(DataDictionary):
    @classmethod
    def __columns__(cls) -> list:
        return list(cls.raw['columns'])

    @classmethod
    def __column__(cls, column_name) -> dict:
        return cls.raw['columns'][column_name]


class Years(DataDictionary):
    @classmethod
    def __years__(cls):
        return list(cls.raw['data_set'])

    @classmethod
    def __year__(cls, year: str) -> dict:
        ret = dict()
        for col in cls.__year_columns__(year):
            ret[col] = dict()
            for k, v in cls.raw['columns'][col]['metadata'].items():
                ret[col][k] = v
            for k, v in cls.raw['columns'][col][year].items():
                ret[col][k] = v
        return ret

    @classmethod
    def __year_columns__(cls, year: str) -> list:
        """return a list of columns that are present in a given year"""
        return [k for k, v in cls.raw['columns'].items() if year in v.keys()]

    @classmethod
    def keys(cls) -> list:
        return list(cls.raw['data_set'].keys())


for c in Columns.__columns__():
    setattr(Columns, c, Columns.__column__(c))

for y in Years.__years__():
    setattr(Years, f"c{y}", Years.__year__(y))
