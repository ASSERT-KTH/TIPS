import json
import os
import subprocess
import sys
import solcx
from src.extractVersion import extractVersion
import docker


def get_slither_report(source_path, version, outputdir):
    print("Getting Slither report...")
    ret = select_version(version)
    if ret != 0:
        print("Error selecting version")
        return ret
    filename = os.path.basename(source_path).replace(".sol", ".slither.json")
    outputpath = os.path.join(outputdir, filename)
    if os.path.exists(outputpath):
        return 0
    ret = run_slither(source_path, outputpath)
    if ret != 0:
        print("Error running slither")
    return ret

def select_version(version):
    cmd = f"solc-select use --always-install {version}"
    ret = subprocess.run(cmd, shell=True, capture_output=True)
    print(ret.stdout.decode('utf-8'))
    print(ret.stderr.decode('utf-8'))
    return ret.returncode

def run_slither(source_path, outputpath):
    cmd = f"slither {source_path} --json {outputpath}"
    res = subprocess.run(cmd, shell=True, capture_output=True)
    print(res.stdout.decode('utf-8'))
    print(res.stderr.decode('utf-8'))
    return res.returncode


def generate_defect_list(source_dir, output_dir):
	path = output_dir
	contractdir = source_dir
	defect_list_path = output_dir

	fileList = os.listdir(path)
	defectList = []
	for f in fileList:
		if not f.endswith('.slither.json'):
			continue
		try:
			if f == 'afterRepair':
				continue
			contract_name = f.replace('.slither.json', '.sol')
			print(contract_name)
			vdict = {}
			vdict['name'] = contract_name
			vdict['defect'] = []
			with open(path+f) as fd:
				content = json.loads(fd.read())
				unchecked_line = []
				reentrancy_line = []
				ac_line = []
				greedy_line = []
				strictb_line = []
				for item in content['results']['detectors']:
					if item['check'] == 'locked-ether':
						location = item['elements'][0]
						contractline = location['type'] + ' ' + location['name']
						lineno = 1
						with open(os.path.join(contractdir, contract_name)) as contract:
							ccontent = contract.readlines()
							for line in ccontent:
								if contractline in line:
									greedy_line.append(lineno)
									break
								lineno+=1
					elif item['check'] == 'incorrect-equality':
						location  = item['elements'][1]
						if 'this.balance' in location['name']:
							vtype = 'strict_balance'
							strictb_line.append(location['source_mapping']['lines'][0])
					elif item['check'] == 'tx-origin':
						location  = item['elements'][1]
						ac_line.append(location['source_mapping']['lines'][0])
						vtype = 'access_control'
					elif item['check'] == 'unchecked-lowlevel' or item['check'] == 'unchecked-send' or item['check'] == 'unused-return':
						vtype = 'unchecked_low_level_calls'
						location = item['elements'][1]
						# contractline = location['name']
						unchecked_line.append(int(location['source_mapping']['lines'][0]))
					elif item['check'] == 'reentrancy-eth' or item['check'] == 'reentrancy-no-eth':
						vtype = 'reentrancy'
						location = item['elements'][1]
						#  contractline = location['name']
						reentrancy_line.append(int(location['source_mapping']['lines'][0]))
				
				if len(greedy_line) > 0:
					cdict = {}
					cdict['lines'] = greedy_line
					cdict['category'] = 'greedy'
					vdict['defect'].append(cdict)
				
				if len(strictb_line) > 0:
					cdict = {}
					cdict['lines'] = strictb_line
					cdict['category'] = 'strict_balance'
					vdict['defect'].append(cdict)
				
				if len(ac_line) > 0:
					cdict = {}
					cdict['lines'] = ac_line
					cdict['category'] = 'access_control'
					vdict['defect'].append(cdict)
				
				if len(reentrancy_line) > 0:
					cdict = {}
					cdict['lines'] = reentrancy_line
					cdict['category'] = 'reentrancy'
					vdict['defect'].append(cdict)
				
				if len(unchecked_line) > 0:
					cdict = {}
					cdict['lines'] = unchecked_line
					cdict['category'] = 'unchecked_low_level_calls'
					vdict['defect'].append(cdict)
			defectList.append(vdict)
		except Exception as e:
			defectList.append('failed ' + str(e))
	with open(os.path.join(defect_list_path, 'defectList.json'), 'w+') as outf:
		outf.write(json.dumps(defectList))


def get_solidity_ast(source_path, version, contract_name, output_dir):
    print("Getting Solidity AST...")
    solcx.install_solc(version)
    
    solcx.set_solc_version(version)
    
    # Read the Solidity file
    with open(source_path, 'r') as file:
        solidity_code = file.read()

    # Compile the Solidity file and get the AST
    compiled_sol = solcx.compile_source(
        solidity_code,
        output_values=["ast"]
    )

    # Extract the AST
    ast = compiled_sol["<stdin>:"+contract_name]['ast']
    filename = os.path.basename(source_path).replace(".sol", ".ast")
    output_ast = os.path.join(output_dir, filename)

    with open(output_ast, 'w') as file:
        json.dump(ast, file, indent=4)

    return output_ast

def run_tips(source_path, output_dir):
    print("Running TIPS...")
    source_dir = os.path.dirname(source_path)+"/"
    cmd = f"python3 ./src/TIPS.py -i {source_dir} -a {output_dir} -d {output_dir} -o {output_dir}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    print(result.stdout)
    print(result.stderr)

    return result.returncode


def main():
    if len(sys.argv) != 4:
        print("Usage: python run_tips.py <source_path> <output_dir> <main_contract>")
        sys.exit(1)
    
    source_path = sys.argv[1]
    output_dir = sys.argv[2] if sys.argv[2].endswith("/") else sys.argv[2] + "/"
    main_contract = sys.argv[3]

    # version = extractVersion(source_path)
    # print("Version: ", version)
    version = "0.4.26"

    get_slither_report(source_path, version, output_dir)

    source_dir = os.path.dirname(source_path) + "/"

    generate_defect_list(source_dir, output_dir)

    get_solidity_ast(source_path, version, main_contract, output_dir)

    run_tips(source_path, output_dir)

if __name__ == "__main__":
    main()



