**Connection to SCITAS clusters:**

Login to {gaspar_username}@izar.epfl.ch (requires vpn)<br>
Note: can connect directly from most editors (extensions available) to have visual access to filesystem.

**Script to run code (with VITA privileges):**

<code>
#!/bin/bash<br>
#SBATCH --chdir {directory}<br>
#SBATCH --nodes 1<br>
#SBATCH --ntasks 1<br>
#SBATCH --account=vita<br>
#SBATCH --cpus-per-task 20<br>
#SBATCH --mem 160G<br>
#SBATCH --time 48:00:00<br>
#SBATCH --gres gpu:1<br>
#SBATCH --job-name={identifier}<br>
#SBATCH --reservation=vita<br>
<br>
module load gcc/8.4.0-cuda python/3.7.7<br>
source /work/vita/mshahver/sceneattack-env/bin/activate<br>
<br>
echo STARTING `date`<br>
python finetune.py<br>
echo FINISHED `date`<br>
</code>
<br>

**Debugging (limited to 60 minutes):**

`Sinteract -g gpu:1 -p debug -c 20 -m 160G -t 60 -r vita`

(wait for resources allocation)

<code>
module load gcc/8.4.0-cuda python/3.7.7<br>
source /work/vita/mshahver/sceneattack-env/bin/activate<br>
<br>
cd {directory}<br>
python finetune.py<br>
</code>
<br>