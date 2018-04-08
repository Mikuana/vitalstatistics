sudo apt update
sudo apt upgrade -y

# install required utilities
sudo apt install p7zip-full

sudo su
mkdir /opt/anaconda && chmod ugo+w /opt/anaconda
exit

wget -O ~/miniconda3.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash ~/miniconda3.sh -b -p /opt/anaconda/miniconda3


# Use AWS CLI to access IAM Role for checkout of repository
apt install python-pip
pip install --upgrade pip
pip install awscli


git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

git clone https://git-codecommit.us-west-2.amazonaws.com/v1/repos/VitalStatistics


# Update Conda binary
/opt/anaconda/miniconda3/bin/conda update -n base conda
# Run conda env update to sync environments
/opt/anaconda/miniconda3/bin/conda env update -f VitalStatistics/data-raw/environment.yml
# Activate environment
source /opt/anaconda/miniconda3/bin/activate VitalStatsFarmer
