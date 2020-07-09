from pathlib import Path

# create directories
for f in ['src', 'gen']:
    Path(f).mkdir(parents=True, exist_ok=True)  # 1st layer directory
    for subf in ['data-preparation', 'analysis', 'paper']:
        Path(f + '/' + subf).mkdir(parents=True, exist_ok=True)  # 2nd layer dir
        for subsubf in ['temp', 'input', 'output']:
            if f == 'gen':
                Path(f + '/' + subf + '/' + subsubf).mkdir(parents=True,
                                                           exist_ok=True)  # 3rd layer dir for 'gen'
