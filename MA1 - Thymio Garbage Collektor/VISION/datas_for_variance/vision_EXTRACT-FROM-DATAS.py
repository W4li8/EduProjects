import numpy as np




if __name__ == '__main__':

    files_VAR = ['datasX_INC10_ROT6_TOTAL.txt', 'datasY_INC10_ROT6_TOTAL.txt','datasTHETA_INC10_TOTAL.txt']
    files_SPEEDCONV = ['datas_speed_variance.txt']

    for f in files_VAR:
        arr = []
        myfile = open(f, 'r')
        lines = myfile.readlines()
        for l in lines :
            if '#' in l:
                continue
            else:
                tab = l.split('|')
                #print(tab)
                arr.append(float(tab[3]))

        print('{} has variance : {} with {} measures'.format(f, np.var(arr), len(lines)-1))

    for f in files_SPEEDCONV:
        speed_arr = []
        conv_arr = []

        myfile = open(f, 'r')
        lines = myfile.readlines()
        for l in lines :
            if '#' in l:
                continue
            else:
                tab = l.split('|')

                speed = float(tab[3])/float(tab[2])
                speed_arr.append(speed)

                conv_arr.append(speed/float(tab[1]))
        print('Speed Conv Factor : {}'.format(np.mean(conv_arr)))
        print('Speed Variance : {}'.format(np.var(speed_arr)))
