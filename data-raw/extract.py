import gzip
from data_dictionary import Years
from pathlib import Path
import os
import shutil
import subprocess
import pandas as pd
import numpy as np
from ftplib import FTP
from tqdm import tqdm

ftp_cdc_url = 'ftp.cdc.gov'
ftp_working_directory = 'pub/Health_Statistics/NCHS/Datasets/DVS/natality'
staged_folder = Path(Path.home(), 'Data/BirthCount/')


def get_zips(zip_destination: Path):
    """
    Obtain zip files for all mapped years if the `fwf.gz` is not present in the specified folder
    """
    if not zip_destination.exists():
        zip_destination.mkdir(parents=True, exist_ok=True)

    for year in Years.keys():
        zip_name = f"Nat{year}{'' if int(year) < 1994 else 'us'}.zip"
        zip_path = Path(zip_destination, zip_name)
        gz_path = Path(zip_destination, f"{year}.fwf.gz")
        if not gz_path.exists() and not zip_path.exists():
            ftp_get(zip_name, zip_path)


def re_zip(zip_destination: Path):
    """
    Unpack zip files and re-compress data file as gzip. The zip file format is an archive which includes multiple
    files, and generally doesn't play well with open source and on-the-fly decompression. Storing files as gzip allows
    us to leave data compressed on disk, and improves ingest performance of fixed width files (I think).
    """
    for year in Years.keys():
        zip_path = Path(zip_destination, f"Nat{year}{'' if int(year) < 1994 else 'us'}.zip")
        unzip_path = Path(zip_destination, f"{year}")
        gz_path = Path(zip_destination, f"{year}.fwf.gz")

        if not gz_path.exists():
            print(f"Unpacking {zip_path}")
            unzip_path.mkdir(exist_ok=True)
            subprocess.check_output(['7z', 'x', zip_path.as_posix(), '-o' + unzip_path.as_posix()])
            source = raw_file(unzip_path)
            destination = gz_path
            print(f"Compressing {source.as_posix()} to {destination.as_posix()}")
            with open(source.as_posix(), 'rb') as f_in:
                with gzip.open(destination, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            shutil.rmtree(unzip_path)


def raw_file(folder: Path) -> Path:
    """ Locate the raw data file by finding the largest file in the folder and assuming """
    sizes = [(os.path.getsize(Path(folder, f)), f) for f in folder.iterdir()]
    sizes.sort(reverse=True)
    return Path(folder, sizes[0][1])


def ftp_get(source_file, destination_path):
    """ Download file from FTP server and provide a progress bar """
    ftp = FTP(ftp_cdc_url)
    ftp.login()
    ftp.cwd(ftp_working_directory)
    total = ftp.size(source_file)

    with open(destination_path, 'wb') as f:
        print(f"Starting download of {destination_path}")
        with tqdm(total=total) as progress_bar:
            def cb(data):
                data_length = len(data)
                progress_bar.update(data_length)
                f.write(data)

            # noinspection SpellCheckingInspection
            ftp.retrbinary('RETR {}'.format(source_file), cb)


def decode(column_map, gz_file, nrows=None) -> pd.DataFrame:
    # we do strange math on start and stop, because the data dictionary uses values verbatim from
    # guides published by the CDC, but these are not zero indexed. So we need to make the start
    # column zero indexed, but ALSO make the tuple behave like a range, where the end value goes
    # one past the column that you want.
    pairs = [(v['start_column'] - 1, v['end_column']) for k, v in column_map.items()]

    kwargs = dict(
        colspecs=pairs,
        header=None,
        names=list(column_map.keys()),
        index_col=False,
        compression='infer',
        nrows=nrows,
        encoding='utf-8'
    )
    try:
        df = pd.read_fwf(gz_file, **kwargs)
    except UnicodeDecodeError:  # if utf-8 decode fails, retry with latin-1/iso-8859
        kwargs['encoding'] = 'iso-8859-1'
        df = pd.read_fwf(gz_file, **kwargs)

    # apply categorical labels
    for k, v in column_map.items():
        # if column has labels, apply them as categorical
        if 'labels' in v.keys():
            ordered = v['ordered'] == "True"
            rename = dict(zip(v['levels'], v['labels']))
            df[k] = pd.Categorical(df[k], ordered=ordered, categories=v['levels']).rename_categories(rename)

        # if column has NA value, convert to int64 extension and cast NA as NaN
        if 'na_value' in v.keys():
            df[k] = pd.Series(df[k].map(lambda x: np.nan if x == v['na_value'] else x), dtype='float')

    return df


def load_year(year: int, nrows=None) -> pd.DataFrame:
    df = decode(Years().__year__(str(year)), Path(staged_folder, f"{year}.fwf.gz"), nrows=nrows)
    df['YEAR'] = int(year)
    return df


def write_subset():
    for year in Years.keys():
        df = load_year(year, nrows=1e5)
        df.to_feather(Path(staged_folder, f'{year}.feather'))


if __name__ == '__main__':
    get_zips(staged_folder)
    re_zip(staged_folder)
    write_subset()
