"""
Use the dictionary provided in this project to run a loop process where values are 
extracted from the fixed width files provided by the CDC FTP server, and converted
into a friendlier comma delimited format that can be read more easily.

This module is meant to be executed from the root of the R package so that it can
locate the appropriate references. When calling this module, your command should
look like:

```sh
python3 data-raw/stage.py
```

"""
import os
import shutil
from ftplib import FTP
from tqdm import tqdm
import subprocess
import json
import random


def loop(start=1968, end=2014, sample=False, **kwargs):
    for year in range(start, end+1):
        manage(year, sample=sample, **kwargs)


def manage(year, remove_zip=False, remove_raw=True, remove_stage=True, sample=False):
    p = PathFinder(year)
    d = SchemaLessDD(p.dictionary)

    if not os.path.exists(p.stage_gz_file):
        if not os.path.exists(p.stage_file):
            if not os.path.exists(p.uz_folder):
                if not os.path.exists(p.zip):
                    ftp_get(p.zip_name, p.zip)  # if the zip doesn't exist, get it from the FTP
                uz(p.zip, p.uz_folder)  # unzip into data folder

            data_dictionary = d.year(year)
            stage(data_dictionary, p.stage_file, p.raw_file(), year, sample=sample)
        mz(p.stage_file)

    if remove_raw and os.path.exists(p.uz_folder):
        shutil.rmtree(p.uz_folder)

    if remove_zip and os.path.exists(p.zip):
        os.remove(p.zip)

    if remove_stage and os.path.exists(p.stage_file):
        os.remove(p.stage_file)


def uz(stage_file, uz_folder):
    """ Unzip CDC file """
    print("Unpacking {}".format(stage_file))
    subprocess.check_output(['unzip', stage_file, '-d', uz_folder])


def mz(stage_file):
    """ Pack output csv into a gzip """
    print("Compressing into {}".format(stage_file))
    subprocess.check_output(['gzip', stage_file])


def ftp_get(zip_file, zip_path):
    ftp = FTP('ftp.cdc.gov')
    ftp.login()
    ftp.cwd('pub/Health_Statistics/NCHS/Datasets/DVS/natality')
    total = ftp.size(zip_file)

    with open(zip_path, 'wb') as f:
        print("Starting download of {}".format(zip_file))
        with tqdm(total=total) as pbar:  # use tqdm to show download progress
            def cb(data):
                l = len(data)
                pbar.update(l)
                f.write(data)
            ftp.retrbinary('RETR {}'.format(zip_file), cb)


class PathFinder(object):
    def __init__(self, year):
        y = str(year)
        zip_file_template = 'Nat{}{}.zip'
        stage_file_template = 'births{}.csv'
        stage_gz_template = 'births{}.csv.gz'
        data_path = os.path.join('data')
        data_raw_path = os.path.join('data-raw')

        self.dictionary = os.path.join(data_path, 'dictionary.json')
        self.zip_name = zip_file_template.format(y, '' if year < 1994 else 'us')
        self.zip = os.path.join(data_raw_path, self.zip_name)
        self.uz_folder = os.path.join(data_raw_path, y)
        self.stage_file = os.path.join(data_raw_path, stage_file_template.format(y))
        self.stage_gz_file = os.path.join(data_raw_path, stage_gz_template.format(y))

    def raw_file(self):
        """ Locate the raw data file by finding the largest file in the folder and assuming """
        sizes = []
        for f in os.listdir(self.uz_folder):
            sizes.append((os.path.getsize(os.path.join(self.uz_folder, f)), f))
        sizes.sort(reverse=True)
        return os.path.join(self.uz_folder, sizes[0][1])


class SchemaLessDD(object):
    def __init__(self, dict_path):
        self.dict_path = dict_path
        self.full_dict = self.materialize()

    def materialize(self):
        """
        Takes a json data dictionary and materializes complete rules about each 
        field and year which is mentioned in the definition, filling in with the
        default values for that field wherever necessary. This a mostly schema-less
        solution to the problem presented by changing data structure by the vital
        statistics birth record data sets.
        :return: a fully materialized python dictionary, where rules for processing 
        a field can be determined by retrieving the codename, followed by the appropriate
        year in the returned dictionary.
        """
        with open(self.dict_path) as f:
            data = json.load(f)

        master = {}
        for col in data:
            col_dict = {}
            for year in [x for x in data[col] if x != 'default']:
                year_dict = data[col][year]
                for prop in data[col]['default']:
                    if prop not in year_dict:
                        year_dict[prop] = data[col]['default'][prop]
                col_dict[year] = year_dict
            master[col] = col_dict

        return master

    def year(self, year):
        """
        Iterate through each field definition in the full dictionary, and check 
        to see if it contains a definition for the year provided to the method.
        :param year: The year that you want to return available fields for
        :return: A subset of the full dictionary, containing only field definitions
        which contained a year definition for the specified year.
        """
        y = str(year)
        d = dict()
        for pair in self.full_dict:
            if y in self.full_dict[pair]:
                d[pair] = self.full_dict[pair][y]
        return d


def stage(dd, stage_file_path, raw_file_path, year, sample=False):
    year = str(year)

    with open(stage_file_path, 'w') as w:
        w.write(','.join([c for c in dd]) + '\n')  # write header line

    handlers = {
        'integer': lambda x: '' if x[0] == ' ' else str(int(x)),
        'logical': lambda x: '' if x == ' ' else str(x),
        'character': lambda x: '' if x[0] == ' ' else '"{}"'.format(x),
        'numeric': lambda x: '' if x[0] == ' ' else str(round(float(x), ndigits=1)),
        'na': lambda x: '',
    }

    with open(stage_file_path, 'a', encoding='utf8') as w:
        with open(raw_file_path, 'rb') as r:
            print("Counting rows in {} file".format(year))
            total = sum(1 for _ in r)
            print("{} rows".format(total))

            randoms = None
            if sample:
                randoms = sorted(random.sample(range(1, total), 30000), reverse=True)

        with open(raw_file_path, encoding='cp1252') as r:
            print("Writing rows for new {} file".format(year))
            lc = 0
            conscript = None

            for line in tqdm(r, total=total):
                lc += 1
                if sample is True and conscript is None:
                    if randoms == []:
                        break
                    else:
                        conscript = randoms.pop()

                if sample is False or lc == conscript:
                    if line.isspace():
                        pass  # this skips any line that is pure whitespace, since it's not data
                    else:
                        w.write(','.join(
                            [handlers[dd[c]['type']]
                             (line[int(dd[c]['start']) - 1:int(dd[c]['end'])])
                             for c in dd
                             ]
                        ) + '\n')

                    conscript = None


if __name__ == '__main__':
    loop(start=2014, end=2014, remove_raw=False, sample=True)
