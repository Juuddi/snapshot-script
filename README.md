# snapshot-script

This script will download the latest snapshot from the [archive](https://archive.quai.network), extract it into the `~/.quai` directory and start the `go-quai` node.

:::note
This script only runs correctly if your `go-quai` is in the home directory. It will exit with an error if it's not.
:::

Clone the repository with

```bash
git clone https://github.com/Juuddi/snapshot-script.git
```

To run the script, you'll need to make it executable first

```bash
chmod +x download.sh
```

Then you can run it with

```bash
./download.sh
```
