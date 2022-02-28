# ==================================================================================================
# Copyright (c) 2022, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 4, 2022
# ==================================================================================================
import os
import copy
import yaml
from yaml.representer import SafeRepresenter

PY_VER = "3.10"
NDK_VER = "23.1.7779620"

NDK_TEMPLATE = f"""
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
mkdir -p $ANDROID_HOME
wget -q https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip
unzip commandlinetools-linux-8092744_latest.zip -d $ANDROID_HOME/cmdline-tools
mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest
yes | sdkmanager --licenses
sdkmanager --install tools
sdkmanager --install platform-tools
sdkmanager --install "ndk;{NDK_VER}"
"""


class Block(str):
    @staticmethod
    def render(dumper, data):
        s = SafeRepresenter.represent_str(dumper, data.lstrip())
        s.style = "|"
        return s


def main():
    # Render blocks as | literal
    yaml.add_representer(Block, Block.render)

    packages = {}
    allowed_groups = ('pip', 'ios', 'android')
    for item in os.listdir("."):
        if os.path.isdir(item) and not item[0] == ".":
            group, *name = item.split("-", 1)
            if group not in allowed_groups:
                continue
            if group in packages:
                packages[group].append(item)
            else:
                packages[group] = [item]

    jobs = {}

    common_steps = [
        {"uses": "actions/checkout@v2"},
        {
            "name": "Setup conda",
            "uses": "conda-incubator/setup-miniconda@v2",
            "with": {
                "auto-update-conda": True,
                "python-version": PY_VER,
            },
        },
        {"name": "Install conda build", "run": "conda install conda-build"},
    ]

    for group, items in packages.items():
        runs_on = "ubuntu-latest"
        group_steps = []
        if group == "android":
            group_steps = [
                {
                    "name": "Setup JDK",
                    "uses": "actions/setup-java@v1",
                    "with": {"java-version": 11},
                },
                {
                    "name": "Setup android NDK",
                    "run": Block(NDK_TEMPLATE),
                },
            ]
        elif group == "ios":
            runs_on = "macos-latest"

        for pkg in items:
            build_step = [
                {
                    "name": "Build recipe",
                    "run": f"conda build --py={PY_VER} {pkg}",
                },
            ]
            steps = common_steps + group_steps + build_step
            job = jobs[pkg] = {
                "runs-on": runs_on,
                "strategy": {"fail-fast": False},
                "steps": copy.deepcopy(steps),
            }

    script = {
        "name": "CI",
        "on": "push",
        "jobs": jobs,
    }

    with open("ci-gen.yml", "w") as f:
        f.write(yaml.dump(script))


if __name__ == "__main__":
    main()
